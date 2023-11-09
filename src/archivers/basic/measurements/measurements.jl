
function save_measurement!(
    ::BasicArchiver, group::Group, measurement::BasicStatisticalMeasurement
)
    group["n_samples"] = measurement.n_samples
    group["sum"] = measurement.sum
    group["upper_confidence"] = measurement.upper_confidence
    group["mean"] = measurement.mean
    group["lower_confidence"] = measurement.lower_confidence
    group["variance"] = measurement.variance
    group["std"] = measurement.std
    group["minimum"] = measurement.minimum
    group["lower_quartile"] = measurement.lower_quartile
    group["median"] = measurement.median
    group["upper_quartile"] = measurement.upper_quartile
    group["maximum"] = measurement.maximum
    group["skew"] = measurement.skew
    group["kurt"] = measurement.kurt
    group["mode"] = measurement.mode
end

function archive!(
    archiver::BasicArchiver, 
    report::BasicReport{<:Metric, GroupStatisticalMeasurement}
)
    if report.to_print
        sorted_measurments = sort(collect(report.measurement.measurements), by = x -> x[1])
        for (species_id, measurement) in sorted_measurments
            mean, minimum = measurement.mean, measurement.minimum
            maximum, std = measurement.maximum, measurement.std
            println("---$(report.metric.name): $species_id---")
            println("Mean: $mean, Min: $minimum, Max: $maximum, Std: $std", )
        end
    end
    if report.to_save
        file = h5open(archiver.archive_path, "a+")
        base_path = "measurements/$(report.generation)/$(report.metric.name)"
        
        # Create or access the group for the generation
        gen_group = get_or_make_group!(file, base_path)
        
        for (species_id, measurement) in report.measurement.measurements
            species_group = get_or_make_group!(gen_group, species_id)
            save_measurement!(archiver, species_group, measurement)
        end
        
        close(file)
    end
end