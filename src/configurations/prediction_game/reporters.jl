export make_reporters

function make_reporters(configuration::PredictionGameConfiguration)
    report_type = configuration.report_type
    print_interval = 0
    save_interval = 0
    if report_type == "silent_test"
        print_interval = 0
        save_interval = 0
    elseif report_type == "verbose_test"
        print_interval = 1
        save_interval = 0
    elseif report_type == "deploy"
        print_interval = 25
        save_interval = 1
    else
        throw(ArgumentError("Unrecognized report type: $report_type"))
    end
    reporters = [
        BasicReporter(
            metric = GlobalStateMetric(),
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = RuntimeMetric(),
            save_interval = save_interval,
            print_interval = print_interval
        ),
        BasicReporter(
            metric = SnapshotSpeciesMetric(),
            save_interval = save_interval, 
            print_interval = 0
        ),
        BasicReporter(
            metric = AggregateSpeciesMetric(submetric = SizeGenotypeMetric()),
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AggregateSpeciesMetric(
                submetric = SizeGenotypeMetric(perform_minimization = true)
            ),
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AggregateSpeciesMetric(submetric = RawFitnessEvaluationMetric()),
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AggregateSpeciesMetric(submetric = ScaledFitnessEvaluationMetric()),
            save_interval = save_interval, 
            print_interval = print_interval
        ),
    ]
    return reporters
end
