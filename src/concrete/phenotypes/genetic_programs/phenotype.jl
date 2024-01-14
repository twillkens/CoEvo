export GeneticProgramPhenotype

using ...Genotypes.GeneticPrograms: GeneticProgramGenotype, if_less_then_else, get_node
import ....Interfaces: act!, create_phenotype, reset!
using ....Abstract

mutable struct GeneticProgramPhenotype <: Phenotype
    id::Int
    tape::Vector{Real}
    head::Int
    linear_nodes::Vector{LinearNode}
end

function GeneticProgramPhenotype(
    genotype::GeneticProgramGenotype, id::Int = 1, tape::Vector{<:Real} = [0.0]
)
    linear_nodes = linearize(genotype)
    head = length(tape)
    GeneticProgramPhenotype(id, tape, head, linear_nodes)
end

function create_phenotype(::PhenotypeCreator, geno::GeneticProgramGenotype, id::Int)
    GeneticProgramPhenotype(geno, id)
end

function reset!(phenotype::GeneticProgramPhenotype)
    phenotype.head = length(phenotype.tape)
end


function read_tape!(phenotype::GeneticProgramPhenotype)
    val = phenotype.tape[phenotype.head]
    phenotype.head -= 1
    if phenotype.head == 0
        phenotype.head = length(phenotype.tape)
    end
    return val
end

function set_tape!(phenotype::GeneticProgramPhenotype, tape::Vector{<:Real})
    phenotype.tape = tape
    phenotype.head = length(tape)
end

function act!(phenotype::GeneticProgramPhenotype, tape::Vector{<:Real} = [0.0, π])
    try
        set_tape!(phenotype, tape)
        # The stack stores intermediate results or operands for function nodes.
        stack = Real[]
        
        # Start iterating over each node in the linearized execution graph.
        i = 1
        while i <= length(phenotype.linear_nodes)
            node = phenotype.linear_nodes[i]
            # If the current node is a TERMINAL:
            if node.type == TERMINAL
                # If the terminal is a 'read' operation, fetch the value from the data array in the phenotype.
                # Otherwise, use the value of the terminal.
                val = (node.value == :read) ? read_tape!(phenotype) : node.value
                
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
            println("Spin: $(phenotype.tape)")
            println(stack)
            #pp(phenotype.linear_nodes)
            throw(ErrorException("Stack should have exactly one value at the end of execution."))
        end
        return pop!(stack)
    catch e
        println("Error in spin: $e")
        println("-------")
        println("Spin: $(phenotype.tape)")
        #println(phenotype.geno)
        println(stack)
        #pp(phenotype.linear_nodes)
        throw(e)
    end
end

act!(phenotype::GeneticProgramPhenotype, value::Real) = act!(phenotype, [value])
