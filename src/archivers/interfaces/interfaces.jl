export archive!

function archive!(archiver::Archiver, report::Report)
    throw(ErrorException("archive! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(report))
    "))
end

function archive!(archiver::Archiver, reports::Vector{<:Report})
    [archive!(archiver, report) for report in reports]
    return nothing
end

function archive!(archiver::Archiver, genotype::Genotype, group::Group)
    throw(ErrorException("save_genotype! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(genotype))"))
end

function archive!(archiver::Archiver, measurement::Measurement, group::Group)
    throw(ErrorException("save_measurement! not implemented for 
        $(typeof(archiver)) and 
        $(typeof(measurement))"))
end

