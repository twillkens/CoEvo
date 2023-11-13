

function archive!(::BasicArchiver, measurement::BasicMeasurement, group::Group)
    group[measurement.name] = measurement.value
end

#function archive!(archiver::BasicArchiver, measurement::BasicGroupMeasurement, group::Group)
#    measurement_group = get_or_make_group!(group, measurement.name)
#    for submeasurement in measurement.measurements
#        archive!(archiver, submeasurement, measurement_group)
#    end
#end

function archive!(
    archiver::BasicArchiver, 
    report::BasicReport{StatisticalSpeciesMetric, <:BasicMeasurement}
)
    if report.to_print
        report_string = "-----------\n"
        statistic_name = get_name(report.metric.submetric)
        report_string *= "species_statistic: $statistic_name, "
        report_string *= "trial: $(report.trial), generation: $(report.generation)\n"
        for species_measurement in report.measurements
            species_name = species_measurement.name
            report_string *= "$species_name: "
            for measurement in species_measurement.measurements
                measurement_name = measurement.name
                if measurement_name in report.measurements_to_print
                    report_string *= "$measurement_name: $(measurement.value), "
                end
            end
            report_string *= "\n"
        end
        println(report_string)
    end

    if report.to_save
        file = h5open(archiver.archive_path, "r+")
        base_path = "generations/$(report.generation)"
        gen_group = get_or_make_group!(file, base_path)
        archive!(archiver, report.measurement, gen_group)
        close(file)
    end

end
