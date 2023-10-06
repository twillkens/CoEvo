module Interfaces

export archive!, save_genotype!

using JLD2: Group
using ..Archivers.Abstract: Archiver
using ...Reporters.Abstract: Report
using ...Species.Genotypes.Abstract: Genotype

function archive!(
    archiver::Archiver,
    generation::Int,
    report::Report
)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(report))
    "))
end

function save_genotype!(archiver::Archiver, genotype_group::Group, genotype::Genotype)
    throw(ErrorException("save_genotype! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(genotype))"))
end

end