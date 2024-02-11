module HillClimber

export HillClimberEvaluator, HillClimberEvaluation, evaluate

import ....Interfaces: evaluate
using ...Clusterers.GlobalKMeans
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ....Abstract
using ....Interfaces
using ...Criteria

Base.@kwdef struct HillClimberEvaluator <: Evaluator
    id::String = "A"
    max_clusters::Int = 5
end

Base.@kwdef struct HillClimberEvaluation <: Evaluation
    id::String
    winner_ids::Vector{Int}
    matrix::OutcomeMatrix
end

function evaluate(
    evaluator::HillClimberEvaluator, 
    species::AbstractSpecies,
    results::Vector{<:Result},
    ::State
)
    matrix = make_distinction_matrix(species.population, results)
    println("row_ids = ", matrix.row_ids)

    winner_ids = Int[]
    for (parent, child) in zip(species.parents, species.children)
        parent_outcomes = matrix[parent.id, :]
        child_outcomes = matrix[child.id, :]
        winner_id = dominates(Maximize(), child_outcomes, parent_outcomes) ? child.id : parent.id
        push!(winner_ids, winner_id)
    end

    evaluation = HillClimberEvaluation(
        id = evaluator.id, winner_ids = winner_ids, matrix = matrix,
    )
    return evaluation
end

end