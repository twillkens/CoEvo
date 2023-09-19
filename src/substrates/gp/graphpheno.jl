export LinearNode, GPPheno, linearize_genotype, spin

# Enum to distinguish between node types
@enum NodeType FUNCTION TERMINAL CONDITIONAL ELSEJUMP

# LinearNode structure for execution
mutable struct LinearNode
    gid::Int
    type::NodeType
    value::Union{Symbol, Function, Real}
    arity::Int
    jump_length::Int
end

function pp(nodes::Vector{LinearNode})
    for (i, node) in enumerate(nodes)
        println("$i: LinearNode(gid: $(node.gid), type: $(node.type), value: $(node.value), arity: $(node.arity), jump: $(node.jump_length))")
    end
end

function linearize_genotype(genotype::GPGeno, node_gid::Int = genotype.root_gid)
    nodes = LinearNode[]

    function traverse(node_gid)
        local_node_list = LinearNode[]
        node = get_node(genotype, node_gid)

        if isa(node.val, Function) && node.val == iflt
            # Linearize the condition nodes first
            first_arg_nodes = traverse(node.child_gids[1])
            second_arg_nodes = traverse(node.child_gids[2])
            append!(local_node_list, first_arg_nodes)
            append!(local_node_list, second_arg_nodes)

            # Capture the starting point for the 'then' branch
            start_then = length(local_node_list) + 1

            # Linearize the 'then' branch nodes
            then_branch_nodes = traverse(node.child_gids[3])
            append!(local_node_list, then_branch_nodes)

            # Capture the starting point for the 'else' branch
            start_else = length(local_node_list) + 2

            else_branch_nodes = traverse(node.child_gids[4])
            # Linearize the 'else' branch nodes
            append!(local_node_list, else_branch_nodes)
            # Determine the jump length
            jump_length = start_else - start_then + 1
            try 
                # Insert the CONDITIONAL node at the starting point of the 'then' branch
                insert!(
                    local_node_list, 
                    start_then, 
                    LinearNode(node_gid, CONDITIONAL, :cond, 0, length(then_branch_nodes) + 2)
                )
                insert!(
                    local_node_list, 
                    start_else,
                    LinearNode(node_gid, ELSEJUMP, :cond, 0, length(else_branch_nodes) + 1)
                )
            catch e
                println("Error in linearize_genotype: $e")
                println("-------")
                println("Linearize: $(genotype)")
                println("\nAll nodes so far")
                pp(nodes)
                println("start_then: $start_then")
                println("start_else: $start_else")
                println("jump_length: $jump_length")
                println("\nLocal Nodes")
                pp(local_node_list)
                throw(e)
            end
        else
            if node.child_gids != []
                children = [traverse(gid) for gid in node.child_gids]
                for child in children
                    append!(local_node_list, child)
                end
            end

            if isa(node.val, Function)
                push!(local_node_list, LinearNode(node_gid, FUNCTION, node.val, length(node.child_gids), 0))
            else
                push!(local_node_list, LinearNode(node_gid, TERMINAL, node.val, 0, 0))
            end
        end

        return local_node_list
    end

    nodes = traverse(node_gid)
    return nodes
end

mutable struct GPPheno <: Phenotype
    ikey::IndivKey
    data::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
    geno::GPGeno
end

function GPPheno(ikey::IndivKey, genotype::GPGeno, data::Vector{<:Real} = [0.0, π])
    linear_nodes = linearize_genotype(genotype)
    head = length(data)
    GPPheno(ikey, data, head, linear_nodes, genotype)
end

function read_from_pheno(pheno::GPPheno)
    val = pheno.data[pheno.head]
    pheno.head -= 1
    if pheno.head == 0
        pheno.head = length(pheno.data)
    end
    return val
end

function set_data!(pheno::GPPheno, data::Vector{<:Real})
    pheno.data = data
    pheno.head = length(data)
end

function spin(pheno::GPPheno, data::Vector{<:Real} = [0.0, π])
    try
        set_data!(pheno, data)
        # The stack stores intermediate results or operands for function nodes.
        stack = Real[]
        
        # Start iterating over each node in the linearized execution graph.
        i = 1
        while i <= length(pheno.linear_nodes)
            node = pheno.linear_nodes[i]
            # If the current node is a TERMINAL:
            if node.type == TERMINAL
                # If the terminal is a 'read' operation, fetch the value from the data array in the phenotype.
                # Otherwise, use the value of the terminal.
                val = (node.value == :read) ? read_from_pheno(pheno) : node.value
                
                # Push the value to the stack.
                push!(stack, val)
                # Move to the next node in the linear execution graph.
                i += 1
                
            # If the current node is a FUNCTION:
            elseif node.type == FUNCTION
                # Fetch the required number of arguments for the function from the stack.
                args = [pop!(stack) for _ in 1:node.arity]
                
                # Evaluate the function with the arguments and push the result back to the stack.
                push!(stack, node.value(reverse(args)...))
                # Move to the next node in the linear execution graph.
                i += 1
                
            # If the current node is a CONDITIONAL (used for my_iflt):
            elseif node.type == CONDITIONAL
                # Check the result of the previous evaluation (e.g., my_iflt condition result).
                # If the condition is true (assumes true for non-zero values), skip the false branch.
                second_result = pop!(stack)
                first_result = pop!(stack)
                if first_result < second_result
                    i += 1
                else
                    i += node.jump_length
                end
            elseif node.type == ELSEJUMP
                i += node.jump_length
            end
        end
        
        # Return the final computed value.
        if length(stack) != 1
            println("-------")
            println("Spin: $(pheno.data)")
            println(pheno.geno)
            println(stack)
            pp(pheno.linear_nodes)
            throw(ErrorException("Stack should have exactly one value at the end of execution."))
        end
        return pop!(stack)
    catch e
        println("Error in spin: $e")
        println("-------")
        println("Spin: $(pheno.data)")
        println(pheno.geno)
        println(stack)
        pp(pheno.linear_nodes)
        throw(e)
    end
end


struct GPPhenoCfg <: PhenoConfig
end

function(cfg::GPPhenoCfg)(ikey::IndivKey, geno::GPGeno)
    GPPheno(ikey, geno)
end