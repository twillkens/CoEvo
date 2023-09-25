module Individuals

export AsexualIndividual, AsexualIndividualConfiguration
export SexualIndividual, SexualIndividualConfiguration


include("types/asexual.jl")
include("types/sexual.jl")

using Random: AbstractRNG

using ....CoEvo.Abstract: Genotype, Individual, IndividualConfiguration, Mutator
using ....CoEvo.Abstract: Mutator, Individual
using ....CoEvo.Utilities.Counters: Counter

function(indiv_cfg::IndividualConfiguration)(id::Int, geno::Genotype, parent_ids::Vector{Int})
    if length(parent_ids) == 1
        return AsexualIndividual(id, geno, parent_ids[1])
    else
        return SexualIndividual(id, geno, parent_ids)
    end
end

function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: AsexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_id)
end

function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: SexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_ids)
end

function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutator(rng, gene_id_counter, indiv) for indiv in indivs]
end

end