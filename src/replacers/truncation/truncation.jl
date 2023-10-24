module Truncation

export TruncationReplacer

import ...Replacers.Interfaces: replace

using Random: AbstractRNG
using ...Species.Abstract: AbstractSpecies
using ...Evaluators.Abstract: Evaluation
using ...Evaluators.ScalarFitness: ScalarFitnessEvaluation
using ..Replacers.Abstract: Replacer

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
    truncated_ids = Set(ids[1:replacer.n_truncate])
    new_population = filter(individual -> individual.id in truncated_ids, candidates)
    return new_population
end

end