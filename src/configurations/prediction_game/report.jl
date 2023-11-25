export ReportConfiguration, SilentReportConfiguration, VerboseTestReportConfiguration
export DeployReportConfiguration, load_report, get_report

using ...Names

abstract type ReportConfiguration end

function make_global_state_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = GlobalStateMetric(),
        save_interval = configuration.save_interval, 
        print_interval = configuration.print_interval
    )
    return reporter
end

function make_runtime_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = RuntimeMetric(),
        save_interval = configuration.save_interval,
        print_interval = configuration.print_interval
    )
    return reporter
end

function make_snapshot_species_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = SnapshotSpeciesMetric(),
        save_interval = configuration.save_interval, 
        print_interval = 0
    )
    return reporter
end

function make_genotype_size_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = AggregateSpeciesMetric(submetric = SizeGenotypeMetric()),
        save_interval = configuration.save_interval,
        print_interval = configuration.print_interval
    )
    return reporter
end

function make_minimized_genotype_size_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = AggregateSpeciesMetric(
            submetric = SizeGenotypeMetric(perform_minimization = true)
        ),
        save_interval = configuration.save_interval,
        print_interval = configuration.print_interval
    )
    return reporter
end

function make_raw_fitness_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = AggregateSpeciesMetric(submetric = RawFitnessEvaluationMetric()),
        save_interval = configuration.save_interval, 
        print_interval = configuration.print_interval
    )
    return reporter
end

function make_scaled_fitness_reporter(configuration::ReportConfiguration)
    reporter = BasicReporter(
        metric = AggregateSpeciesMetric(submetric = ScaledFitnessEvaluationMetric()),
        save_interval = configuration.save_interval, 
        print_interval = configuration.print_interval
    )
    return reporter
end

struct SilentReportConfiguration <: ReportConfiguration
    id::String
end

function archive!(configuration::SilentReportConfiguration, file::File)
    base_path = "configuration/report"
    file["$base_path/id"] = configuration.id
end

function SilentReportConfiguration(; id::String = "silent", kwargs...)
    configuration = SilentReportConfiguration(id)
    return configuration
end

requires_archive(::SilentReportConfiguration) = false

function make_reporters(::SilentReportConfiguration)
    reporters = [NullReporter()]
    return reporters
end

struct VerboseTestReportConfiguration <: ReportConfiguration
    id::String
    print_interval::Int
    save_interval::Int
end

function archive!(configuration::VerboseTestReportConfiguration, file::File)
    base_path = "configuration/report"
    file["$base_path/id"] = configuration.id
    file["$base_path/print_interval"] = configuration.print_interval
    file["$base_path/save_interval"] = configuration.save_interval
end

function VerboseTestReportConfiguration(;
    id::String = "verbose_test", save_interval::Int = 0, print_interval::Int = 1, kwargs...
)
    configuration = VerboseTestReportConfiguration(
        id,
        print_interval,
        save_interval,
    )
    return configuration
end

function make_reporters(configuration::VerboseTestReportConfiguration)
    reporters = [
        make_global_state_reporter(configuration),
        make_runtime_reporter(configuration),
        make_genotype_size_reporter(configuration),
        make_raw_fitness_reporter(configuration),
    ]
    return reporters
end

struct DeployReportConfiguration <: ReportConfiguration
    id::String
    print_interval::Int
    save_interval::Int
end

function archive!(configuration::DeployReportConfiguration, file::File)
    base_path = "configuration/report"
    file["$base_path/id"] = configuration.id
    file["$base_path/print_interval"] = configuration.print_interval
    file["$base_path/save_interval"] = configuration.save_interval
end

function DeployReportConfiguration(; 
    id::String = "deploy", print_interval::Int = 50, save_interval::Int = 1, kwargs...)
    configuration = DeployReportConfiguration(id, print_interval, save_interval,)
    return configuration
end

function make_reporters(configuration::DeployReportConfiguration)
    reporters = [
        make_global_state_reporter(configuration),
        make_runtime_reporter(configuration),
        make_snapshot_species_reporter(configuration),
        make_genotype_size_reporter(configuration),
        make_minimized_genotype_size_reporter(configuration),
        make_raw_fitness_reporter(configuration),
        make_scaled_fitness_reporter(configuration),
    ]
    return reporters
end

function requires_archive(configuration::ReportConfiguration)
    return configuration.save_interval > 0
end

const ID_TO_REPORT_MAP = Dict(
    "silent" => SilentReportConfiguration,
    "verbose_test" => VerboseTestReportConfiguration,
    "deploy" => DeployReportConfiguration,
)

function get_report(id::String; kwargs...)
    report_type = get(ID_TO_REPORT_MAP, id, nothing)
    if report_type === nothing
        error("Unknown report type: $id")
    end
    report = report_type(; id, kwargs...)
    return report
end

function load_report(file::File)
    base_path = "configuration/report"
    id = read(file["$base_path/id"])
    report_type = get(ID_TO_REPORT_MAP, id, nothing)

    if report_type === nothing
        error("Unknown report type: $id")
    end
    report = load_type(report_type, file, base_path)
    return report
end