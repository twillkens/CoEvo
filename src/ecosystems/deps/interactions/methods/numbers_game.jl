module NumbersGame

using ....Interactions.Environments.Abstract: Environment, EnvironmentCreator
using ...Environments.Types.Stateless: StatelessEnvironment
using ....Interactions.Domains.Types.NumbersGame: NumbersGameDomain
using ....Metrics.Outcome.Types.NumbersGame: Control, Sum, Gradient, Focusing, Relativism
using ....Species.Phenotypes.Vectors.Basic: VectorPhenotype
using ....Species.Phenotypes.Interfaces: act


function create_environment(
    ::EnvironmentCreator, 
    interaction_id::String,
    domain::NumbersGameDomain,
    indiv_ids::Vector{Int},
    phenotypes::Vector{<:VectorPhenotype}
)
    return StatelessEnvironment(interaction_id, domain, indiv_ids, phenotypes)
end

function get_outcome_set(env::Environment{NumbersGameDomain, <:VectorPhenotype})
    A, B = act(env.entities[1], nothing), act(env, env.entities[2], nothing)
    get_outcome_set(env.domain.outcome_metric, A, B)
end

"""
    outcome_decision(result::Bool)

Helper function to determine the outcome based on a given decision criterion.
"""
function outcome_decision(result::Bool)
    return result ? [1.0, 0.0] : [0.0, 1.0]
end

"""
    get_outcome_set(::Control, A::Vector{<:Real}, B::Vector{<:Real})

For Control, always return [1.0, 1.0].
"""
function get_outcome_set(::Control, A::Vector{<:Real}, B::Vector{<:Real})
    return [1.0, 1.0]
end

"""
    get_outcome_set(::Sum, A::Vector{<:Real}, B::Vector{<:Real})

Return outcome based on the sum of vectors A and B.
"""
function get_outcome_set(::Sum, A::Vector{<:Real}, B::Vector{<:Real})
    sumA, sumB = sum(A), sum(B)
    return outcome_decision(sumA > sumB)
end

"""
    get_outcome_set(::Gradient, A::Vector{<:Real}, B::Vector{<:Real})

Return outcome based on comparing individual elements of vectors A and B.
"""
function get_outcome_set(::Gradient, A::Vector{<:Real}, B::Vector{<:Real})
    compare_results = [v1 > v2 for (v1, v2) in zip(A, B)]
    return outcome_decision(sum(compare_results) > length(A) / 2)
end

"""
    get_outcome_set(::Focusing, A::Vector{<:Real}, B::Vector{<:Real})

Return outcome based on the maximum absolute difference between vectors A and B.
"""
function get_outcome_set(::Focusing, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmax(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end

"""
    get_outcome_set(::Relativism, A::Vector{<:Real}, B::Vector{<:Real})

Return outcome based on the minimum absolute difference between vectors A and B.
"""
function get_outcome_set(::Relativism, A::Vector{<:Real}, B::Vector{<:Real})
    idx = findmin(abs.(A - B))[2]
    return outcome_decision(A[idx] > B[idx])
end


end