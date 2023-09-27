export LinearNode, linearize

using ....Individuals.Genotypes.GeneticPrograms: BasicGeneticProgramGenotype, get_node

# Enum to distinguish between node types
@enum NodeType FUNCTION TERMINAL CONDITIONAL ELSEJUMP

# LinearNode structure for execution
mutable struct LinearNode
    id::Int
    type::NodeType
    value::Union{Symbol, Function, Real}
    arity::Int
    jump_length::Int
end

function Base.show(io::IO, nodes::Vector{LinearNode})
    for (i, node) in enumerate(nodes)
        print(io, "$i: LinearNode(id: $(node.id), type: $(node.type), value: $(node.value), arity: $(node.arity), jump: $(node.jump_length))\n")
    end
end

function linearize(genotype::BasicGeneticProgramGenotype, node_id::Int = genotype.root_id)
    nodes = LinearNode[]

    function traverse(node_id)
        local_node_list = LinearNode[]
        node = get_node(genotype, node_id)

        if isa(node.val, Function) && node.val == iflt
            # Linearize the condition nodes first
            first_arg_nodes = traverse(node.child_ids[1])
            second_arg_nodes = traverse(node.child_ids[2])
            append!(local_node_list, first_arg_nodes)
            append!(local_node_list, second_arg_nodes)

            # Capture the starting point for the 'then' branch
            start_then = length(local_node_list) + 1

            # Linearize the 'then' branch nodes
            then_branch_nodes = traverse(node.child_ids[3])
            append!(local_node_list, then_branch_nodes)

            # Capture the starting point for the 'else' branch
            start_else = length(local_node_list) + 2

            else_branch_nodes = traverse(node.child_ids[4])
            # Linearize the 'else' branch nodes
            append!(local_node_list, else_branch_nodes)
            # Determine the jump length
            jump_length = start_else - start_then + 1
            try 
                # Insert the CONDITIONAL node at the starting point of the 'then' branch
                insert!(
                    local_node_list, 
                    start_then, 
                    LinearNode(node_id, CONDITIONAL, :cond, 0, length(then_branch_nodes) + 2)
                )
                insert!(
                    local_node_list, 
                    start_else,
                    LinearNode(node_id, ELSEJUMP, :cond, 0, length(else_branch_nodes) + 1)
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
            if node.child_ids != []
                children = [traverse(id) for id in node.child_ids]
                for child in children
                    append!(local_node_list, child)
                end
            end

            if isa(node.val, Function)
                push!(local_node_list, LinearNode(node_id, FUNCTION, node.val, length(node.child_ids), 0))
            else
                push!(local_node_list, LinearNode(node_id, TERMINAL, node.val, 0, 0))
            end
        end

        return local_node_list
    end

    nodes = traverse(node_id)
    return nodes
end