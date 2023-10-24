export archive!, save_genotype!

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
