export archive!

using ..Genotypes: GenotypeCreator


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

function load(
    archiver::Archiver, 
    genotype_creator::GenotypeCreator,
    group::Group
)
    throw(ErrorException("load not implemented for 
        $(typeof(archiver)) and 
        $(typeof(genotype_creator))"))
end

