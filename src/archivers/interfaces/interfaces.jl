export archive!, load

using ..Genotypes: GenotypeCreator
using ..Abstract.States: State


function archive!(archiver::Archiver, genotype::Genotype, group::Group)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(genotype))"))
end

function archive!(archiver::Archiver, measurement::Measurement, group::Group)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(measurement))"))
end

function archive!(archiver::Archiver, state::State)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(state))"))
end

function load(
    archiver::Archiver, 
    genotype_creator::GenotypeCreator,
    group::Group
)
    throw(ErrorException("load not implemented for 
        $(typeof(archiver)) and 
        $(typeof(genotype_creator))"))
end

function load(file::File, base_path::String, genotype_creator::GenotypeCreator)
    throw(ErrorException("load not implemented for 
        $(typeof(file)) and 
        $(typeof(genotype_creator))"))
end

