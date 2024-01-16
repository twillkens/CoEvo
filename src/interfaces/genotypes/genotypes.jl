export create_genotypes, minimize, get_size, convert_to_dict, create_from_dict

using ..Abstract
using HDF5: Group, File


function create_genotypes(genotype_creator::GenotypeCreator, n_genotypes::Int, state::State)
    genotype_creator = typeof(genotype_creator)
    n_genotypes = typeof(n_genotypes)
    state = typeof(state)
    error("create_genotypes not implemented for $genotype_creator, $n_genotypes, $state")
end

function minimize(genotype::Genotype)
    genotype = typeof(genotype)
    error("Default genotype minimization for $genotype not implemented.")
end

function get_size(genotype::Genotype)
    genotype = typeof(genotype)
    error("Default genotype size for $genotype not implemented.")
end

function convert_to_dict(genotype::Genotype)
    genotype = typeof(genotype)
    error("convert_to_dict not implemented for $genotype")
end

function create_from_dict(genotype_creator::GenotypeCreator, dict::Dict)
    genotype_creator_type = typeof(genotype_creator)
    dict = typeof(dict)
    error("create_from_dict not implemented for $genotype_creator_type, $dict")
end