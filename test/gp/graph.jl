using Test
using Random
using StableRNGs
using Distributed
@everywhere using CoEvo
using CoEvo.Base.Coev
using CoEvo.Base.Common
using CoEvo.Base.Reproduction
using CoEvo.Base.Indivs.GP
using CoEvo.Base.Indivs.GP: GPGeno, ExprNode, Terminal, GPMutator, FuncAlias
using CoEvo.Base.Indivs.GP: GPGenoCfg, GPGenoArchiver
using CoEvo.Base.Indivs.GP: get_node, get_child_index, get_ancestors, get_descendents
using CoEvo.Base.Indivs.GP: addfunc, rmfunc, swapnode, inject_noise, splicefunc
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin

using CoEvo.Domains.SymRegression
using CoEvo.Domains.SymRegression: stir
using CoEvo.Base.Jobs
using CoEvo.Domains.ContinuousPredictionGame


function my_iflt(first_arg, second_arg, then_arg, else_arg)
    first_arg = isa(first_arg, Expr) ? eval(first_arg) : first_arg
    second_arg = isa(second_arg, Expr) ? eval(second_arg) : second_arg
    if first_arg < second_arg
        then_arg = isa(then_arg, Expr) ? eval(then_arg) : then_arg
        return then_arg
    else
        else_arg = isa(else_arg, Expr) ? eval(else_arg) : else_arg
        return else_arg
    end
end

function my_challenge()
    GPGeno(
        root_gid = 1,
        funcs = Dict(
            1 => ExprNode(1, nothing, my_iflt, [5, 2, 8, 3]),
            2 => ExprNode(2, 1, +, [6, 7]),
            3 => ExprNode(3, 1, sin, [4]),
            4 => ExprNode(4, 3, *, [9, 10]),
            10 => ExprNode(10, 4, +, [11, 12]),
        ),
        terms = Dict(
            5 => ExprNode(5, 1, π),
            6 => ExprNode(6, 1, π),
            7 => ExprNode(7, 2, :read),
            8 => ExprNode(8, 1, :read),
            9 => ExprNode(9, 4, :read),
            11 => ExprNode(11, 10, :read),
            12 => ExprNode(12, 10, -3/2),
        ),
    )
end

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
        println("$i: LinearNode(gid: $(node.gid), type: $(node.type), value: $(node.value), arity/jump: $(node.arity))")
    end
end


function linearize_genotype(genotype::GPGeno, node_gid::Int = genotype.root_gid)
    nodes = LinearNode[]

    function traverse(node_gid)
        local_node_list = LinearNode[]
        node = get_node(genotype, node_gid)

        if isa(node.val, Function) && node.val == my_iflt
            # Linearize the condition nodes first
            first_arg_nodes = traverse(node.child_gids[1])
            second_arg_nodes = traverse(node.child_gids[2])
            append!(local_node_list, first_arg_nodes)
            append!(local_node_list, second_arg_nodes)

            # Capture the starting point for the 'then' branch
            println("node list after adding first conditionals: ")
            pp(local_node_list)
            start_then = length(local_node_list) + 1

            # Linearize the 'then' branch nodes
            then_branch_nodes = traverse(node.child_gids[3])
            append!(local_node_list, then_branch_nodes)
            println("node list after adding then: ")
            pp(local_node_list)

            # Capture the starting point for the 'else' branch
            start_else = length(local_node_list) + 1

            else_branch_nodes = traverse(node.child_gids[4])
            # Linearize the 'else' branch nodes
            append!(local_node_list, else_branch_nodes)
            println("node list after adding else: ")
            pp(local_node_list)
            # Determine the jump length
            jump_length = start_else - start_then + 1

            println("start then: ", start_then)
            println("start else: ", start_else)
            println("jump length: ", jump_length)

            # Insert the CONDITIONAL node at the starting point of the 'then' branch
            insert!(
                local_node_list, 
                start_then, 
                LinearNode(node_gid, CONDITIONAL, :cond, 0, length(then_branch_nodes) + 2)
            )
            insert!(
                local_node_list, 
                start_else + jump_length - 1,
                LinearNode(node_gid, ELSEJUMP, :cond, 0, length(else_branch_nodes) + 1)
            )
            println("node list after adding conditional: ")
            pp(local_node_list)
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

mutable struct GPPheno
    data::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
end

function GPPheno(genotype::GPGeno, data::Vector{<:Real} = [0.0, π])
    linear_nodes = linearize_genotype(genotype)
    head = length(data)
    GPPheno(data, head, linear_nodes)
end

function read_from_pheno(pheno::GPPheno)
    println("--reading--")
    println("tape: ", pheno.data)
    println("head: ", pheno.head)
    val = pheno.data[pheno.head]
    println("val: ", val)
    pheno.head -= 1
    if pheno.head == 0
        pheno.head = length(pheno.data)
    end
    println("new head: ", pheno.head)
    return val
end
function spin(pheno::GPPheno)
    # The stack stores intermediate results or operands for function nodes.
    stack = Real[]
    
    # Start iterating over each node in the linearized execution graph.
    i = 1
    println("---------spinning---------")
    println(pheno.linear_nodes)
    while i <= length(pheno.linear_nodes)
        node = pheno.linear_nodes[i]
        println("i: ", i)
        println("Current node: ", node)
        println("Current stack: ", stack)
        
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
            println("first result: ", first_result)
            println("second result: ", second_result)
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
        throw(ErrorException("Stack should have exactly one value at the end of execution."))
    end
    return pop!(stack)
end

pheno = GPPheno(my_challenge())
println("answer 1: ", spin(pheno))
pheno.data = [0.0, π, 0.0]
pheno.head = 3
println("answer 2: ", spin(pheno))