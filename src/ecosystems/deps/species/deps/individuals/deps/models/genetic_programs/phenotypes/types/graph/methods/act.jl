export act

function read_tape!(pheno::PlayerPianoPhenotype)
    val = pheno.tape[pheno.head]
    pheno.head -= 1
    if pheno.head == 0
        pheno.head = length(pheno.tape)
    end
    return val
end

function set_tape!(pheno::PlayerPianoPhenotype, data::Vector{<:Real})
    pheno.tape = tape
    pheno.head = length(data)
end

function act(pheno::PlayerPianoPhenotype, tape::Vector{<:Real} = [0.0, π])
    try
        set_tape!(pheno, tape)
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
            println("Spin: $(pheno.date)")
            println(pheno.geno)
            println(stack)
            pp(pheno.linear_nodes)
            throw(ErrorException("Stack should have exactly one value at the end of execution."))
        end
        return pop!(stack)
    catch e
        println("Error in spin: $e")
        println("-------")
        println("Spin: $(pheno.tape)")
        println(pheno.geno)
        println(stack)
        pp(pheno.linear_nodes)
        throw(e)
    end
end

act(pheno::PlayerPianoPhenotype, value::{<:Real} = act(pheno, [val]))