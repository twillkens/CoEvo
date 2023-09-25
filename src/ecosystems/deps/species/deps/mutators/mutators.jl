module Mutators

export DefaultMutator

using Random: AbstractRNG
using ....CoEvo.Abstract: Mutator, Individual
using ....CoEvo.Utilities.Counters: Counter
using ..Individuals: AsexualIndividual

Base.@kwdef struct DefaultMutator <: Mutator end


function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indiv::I
) where {I <: AsexualIndividual}
    geno = mutator(rng, gene_id_counter, indiv.geno)
    I(indiv.id, geno, indiv.parent_id)
end

function(mutator::Mutator)(
    rng::AbstractRNG, gene_id_counter::Counter, indivs::Vector{<:Individual}
)
    [mutator(rng, gene_id_counter, indiv) for indiv in indivs]
end

end