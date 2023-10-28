module Truncation

export TruncationReplacer

import ..Replacers: replace

using Random: AbstractRNG
using ...Species: AbstractSpecies
using ...Evaluators: Evaluation
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluation
using ..Replacers: Replacer

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    n_truncate::Int = 50
end

# We assume the existence of a `records` field in the evaluation, which is a vector of records
# as well as an `id` field in each record, which is an integer. and that the records are sorted
# in descending order by preference
function replace(
    replacer::TruncationReplacer,
    ::AbstractRNG,
    species::AbstractSpecies,
    evaluation::Evaluation
)
    candidates = [species.population ; species.children]
    ids = [record.id for record in evaluation.records]
    #println("candidate_ids:", ids)
    #println("ids: ", ids)
    end_index = length(ids) - replacer.n_truncate
    truncated_ids = Set(ids[1:end_index])
    #println("truncated_ids: ", truncated_ids)
    new_population = filter(individual -> individual.id in truncated_ids, candidates)
    return new_population
end

end