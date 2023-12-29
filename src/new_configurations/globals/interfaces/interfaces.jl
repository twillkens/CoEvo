export get_n_generations, get_n_workers, get_trial, make_random_number_generator
export make_performer

using ...Counters.Basic: BasicCounter
using ...Performers.Basic: BasicPerformer

get_n_generations(configuration::GlobalConfiguration) = configuration.n_generations

get_n_workers(configuration::GlobalConfiguration) = configuration.n_workers

get_trial(configuration::GlobalConfiguration) = configuration.trial

function make_random_number_generator(configuration::GlobalConfiguration)
    throw(ErrorException("make_random_number_generator not implemented for $(typeof(configuration))"))
end

make_performer(config::GlobalConfiguration) = BasicPerformer(n_workers = config.n_workers)