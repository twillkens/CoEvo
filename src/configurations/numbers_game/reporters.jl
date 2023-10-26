
function make_reporters(configuration::NumbersGameConfiguration)
    reporters = Reporter[]
    report_type = configuration.report_type
    print_interval = 0
    save_interval = 0
    if report_type == :silent_test
        runtime_reporter = RuntimeReporter(print_interval = 0)
        return runtime_reporter, reporters
    elseif report_type == :verbose_test
        print_interval = 1
        save_interval = 0
    elseif report_type == :deploy
        print_interval = 25
        save_interval = 1
    else
        throw(ArgumentError("Unrecognized report type: $report_type"))
    end
    runtime_reporter = RuntimeReporter(print_interval = print_interval)
    reporters = Reporter[
        BasicReporter(
            metric = GenotypeSum(), 
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AllSpeciesFitness(), 
            save_interval = save_interval, 
            print_interval = print_interval
        ),
        BasicReporter(
            metric = AllSpeciesIdentity(), 
            save_interval = save_interval, 
            print_interval = 0
        ),
    ]
    return runtime_reporter, reporters
end