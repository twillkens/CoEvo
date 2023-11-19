Base.@kwdef struct BasicArchiver <: Archiver 
    archive_path::String = "archive.h5"
end

function archive!(::BasicArchiver, ::NullReport)
    return
end

function archive!(::BasicArchiver, ::Vector{<:NullReport})
    return
end

function get_category(full_key::String)::String
    split_keys = split(full_key, "/")
    return join(split_keys[1:end-1], "/")
end

function get_label(full_key::String)::String
    split_keys = split(full_key, "/")
    return split_keys[end]
end

function archive!(::BasicArchiver, value::Any, group::Group, label::String)
    group[label] = value
end

function archive!(archiver::BasicArchiver, value::Genotype, group::Group, label::String)
    group = get_or_make_group!(group, label)
    archive!(archiver, value, group)
end

function archive!(
    archiver::BasicArchiver, measurement::BasicMeasurement, file::File, base_path::String = ""
)
    category_path = get_category(measurement.name)
    group_path = "$(base_path)/$(category_path)"
    group = get_or_make_group!(file, group_path)
    label = get_label(measurement.name)
    archive!(archiver, measurement.value, group, label)
end

function archive!(archiver::BasicArchiver, reports::Vector{<:BasicReport})
    reports_to_print = [report for report in reports if report.to_print]
    print_reports(reports_to_print)
    reports_to_save = [report for report in reports if report.to_save]
    if length(reports_to_save) == 0
        return
    end

    file = h5open(archiver.archive_path, "r+")
    for report in reports_to_save
        base_path = "generations/$(report.generation)"
        for measurement in report.measurements
            archive!(archiver, measurement, file, base_path)
        end
    end
    close(file)
end
