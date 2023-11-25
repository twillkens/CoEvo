module Basic

export NullReport, NullReporter, BasicReport, BasicReporter, create_report, print_reports

import ..Reporters: create_report, print_reports

using DataStructures: OrderedDict
using ...Metrics: Metric, Measurement, measure
using ...Metrics.Common: NullMetric
using ...States: State
using ..Reporters: Reporter, Report

struct NullReport <: Report end

struct NullReporter <: Reporter end

function create_report(::NullReporter, ::State)
    return NullReport()
end

Base.@kwdef struct BasicReport{MET <: Metric, MEA <: Measurement} <: Report
    metric::MET
    measurements::Vector{MEA}
    trial::Int = 1
    generation::Int = 1
    to_print::Bool = true
    to_save::Bool = false
end

Base.@kwdef struct BasicReporter{M} <: Reporter
    metric::M
    print_interval::Int = 1
    save_interval::Int = 0
end

function create_report(reporter::BasicReporter, state::State)
    metric = reporter.metric
    trial = state.trial
    generation = state.generation
    to_print = reporter.print_interval > 0 && generation % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && generation % reporter.save_interval == 0
    if !to_print && !to_save
        return BasicReport(NullMetric(), Measurement[], trial, generation, false, false)
    end
    measurements = measure(metric, state)
    report = BasicReport(metric, measurements, trial, generation, to_print, to_save)
    return report
end

function process_measurements(measurements)
    nested_measurements = Dict()
    for m in measurements
        insert_measurement!(nested_measurements, m)
    end
    return nested_measurements
end

function insert_measurement!(dict, measurement)
    parts = split(measurement.name, '/')
    last_index = length(parts)
    current_dict = dict

    for i in 1:last_index
        part = parts[i]
        if i == last_index
            current_dict[part] = measurement.value
        else
            next_dict = get!(current_dict, part, Dict())
            current_dict[part] = next_dict  # Update the reference in the parent dictionary
            current_dict = next_dict  # Move to the next level
        end
    end
end

# Helper function to extract the category from the full key
function get_category(full_key)
    split_keys = split(full_key, "/")
    return join(split_keys[1:end-1], "/")
end

function flatten_measurements(metric, dict, prefix = "")
    str = ""
    sorted_pairs = sort(collect(dict), by = first)  # Sort pairs by key

    # Buffer to accumulate measurements for each category
    measurement_buffer = ""
    current_category = ""

    for (key, value) in sorted_pairs
        full_key = prefix == "" ? key : prefix * "/" * key

        if isa(value, Dict)
            # Process nested dictionaries
            nested_str = flatten_measurements(metric, value, full_key)
            if !isempty(nested_str)
                if !isempty(measurement_buffer)
                    str *= current_category * ": --  " * chop(measurement_buffer, tail = 2) * "\n"
                    measurement_buffer = ""  # Reset the buffer for the next category
                end
                current_category = full_key
                str *= nested_str  # Append the nested measurements
            end
        elseif metric.to_print == "all" || key ∈ metric.to_print
            # Determine if this key-value pair belongs to a new category
            category = get_category(full_key)
            if category != current_category
                if !isempty(measurement_buffer)
                    str *= current_category * " -- " * chop(measurement_buffer, tail = 2) * "\n"
                end
                current_category = category
                measurement_buffer = ""  # Start accumulating new category
            end

            # Append measurement to buffer
            measurement_str = "$key: "
            measurement_str *= isa(value, Real) ? string(round(value, digits = 3)) : string(value)
            measurement_buffer *= measurement_str * ", "
        end
    end

    # Add remaining measurements in the buffer
    if !isempty(measurement_buffer)
        str *= current_category * " -- " * chop(measurement_buffer, tail = 2) * "\n"
    end

    return str
end

function print_reports(reports::Vector{R}, io::IO = stdout) where {R <: BasicReport}
    if isempty(reports)
        return
    end

    # Assuming the trial and generation numbers are the same for all reports,
    # use the first report for the header.
    header_str = "----------Trial $(reports[1].trial), Generation $(reports[1].generation)----------\n"

    # Process and concatenate measurements from all reports
    str = ""
    for report in reports
        nested_measurements = process_measurements(report.measurements)
        str *= flatten_measurements(report.metric, nested_measurements)
    end

    # Combine the header and the measurements
    final_str = header_str * str
    print(io, final_str)
end

end