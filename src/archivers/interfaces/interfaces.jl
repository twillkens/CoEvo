export archive!, save_genotype!, save_measurement!, archive_reports!

function archive!(archiver::Archiver, report::Report)
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

function save_measurement!(archiver::Archiver, species_group::Group, measurement::Measurement)
    throw(ErrorException("save_measurement! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(measurement))"))
end

function archive_reports!(archiver::Archiver, reports::Vector{<:Report})
    [archive!(archiver, report) for report in reports]
    return nothing
end
