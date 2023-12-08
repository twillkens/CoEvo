
function get_scaled_fitness(evaluation::ScalarFitnessEvaluation, id::Int)
    record = first(filter(record -> record.id == id, evaluation.records))
    return record.scaled_fitness
end

function get_scaled_fitness(evaluations::Vector{<:ScalarFitnessEvaluation}, id::Int)
    for evaluation in evaluations
        for record in evaluation.records
            if record.id == id
                return record.scaled_fitness
            end
        end
    end
    throw(ErrorException("Could not find id $id in evaluations."))
end