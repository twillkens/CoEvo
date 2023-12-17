module Truncation

export TruncationReplacer

import ..Replacers: replace

using Random: AbstractRNG
using ...Species: AbstractSpecies, get_individuals_to_evaluate
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
    #println("length population: ", length(species.population))
    candidates = get_individuals_to_evaluate(species)
    #println("length candidates: ", length(candidates))
    if length(candidates) != length(species.population)
        throw(ErrorException("length candidates != length population"))
    end
    #println("n_truncate = ", replacer.n_truncate)
    #println("candidates = ", candidates)
    #println("ids: ", ids)
    records = sort(evaluation.records, by = record -> record.fitness, rev = true)
    #println("candidate ids: ", [candidate.id for candidate in candidates])
    ids = [record.id for record in records]
    #println("record_ids:", ids)
    end_index = length(ids) - replacer.n_truncate
    truncated_ids = Set(ids[1:end_index])
    #println("truncated_ids: ", truncated_ids)
    new_population = filter(individual -> individual.id in truncated_ids, candidates)
    #println("new_population = ", new_population)
    return new_population
end

end