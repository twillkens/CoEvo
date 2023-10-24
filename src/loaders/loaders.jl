module Loaders

export Abstract, Interfaces, Concrete

include("abstract/abstract.jl")
using .Abstract: Abstract

include("interfaces/interfaces.jl")
using .Interfaces: Interfaces

include("concrete/concrete.jl")
using .Concrete: Concrete

using JLD2: Group
using ...CoEvo.Ecosystems.Species.Individuals: Individual
using ..Loaders.Abstract: Loader

function load_individual(loader::Loader, individual_group::Group)
    parent_ids = individual_group["parent_ids"]
    geno_group = individual_group["genotype"]
    genotype = load_genotype(loader, geno_group)
    # Assuming you have an Individual constructor that takes parent_ids and genotype as arguments
    return Individual(parent_ids, genotype)
end

end


