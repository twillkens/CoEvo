import ...Abstract.States: get_n_generations, get_n_workers, get_trial, get_seed
import ..GlobalConfigurations: make_performer

export ExperimentConfiguration, make_ecosystem_creator, make_archivers, make_job_creator, make_performer
export get_n_generations, get_n_workers, get_trial, get_seed

make_ecosystem_creator(::ExperimentConfiguration) = throw(ErrorException("make_ecosystem_creator not implemented"))
make_archivers(::ExperimentConfiguration) = throw(ErrorException("make_archivers not implemented"))
make_job_creator(::ExperimentConfiguration) = throw(ErrorException("make_job_creator not implemented"))
#make_performer(::ExperimentConfiguration) = throw(ErrorException("make_performer not implemented"))

get_n_generations(
    config::ExperimentConfiguration
) = get_n_generations(config.globals)

get_n_workers(
    config::ExperimentConfiguration
) = get_n_workers(config.globals)

get_trial(
    config::ExperimentConfiguration
) = get_trial(config.globals)

get_seed(
    config::ExperimentConfiguration
) = get_seed(config.globals)


make_performer(config::ExperimentConfiguration) = make_performer(config.globals)
    
