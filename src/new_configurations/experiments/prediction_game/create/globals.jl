export get_n_generations, get_n_workers, get_trial, make_random_number_generator
export make_performer

import ...NewConfigurations.GlobalConfigurations: get_n_generations, get_n_workers, get_trial
import ...NewConfigurations.GlobalConfigurations:  make_random_number_generator


get_n_generations(
    config::PredictionGameExperimentConfiguration
) = get_n_generations(config.globals)

get_n_workers(
    config::PredictionGameExperimentConfiguration
) = get_n_workers(config.globals)

get_trial(
    config::PredictionGameExperimentConfiguration
) = get_trial(config.globals)

function make_random_number_generator(
    config::PredictionGameExperimentConfiguration
)
    return make_random_number_generator(config.globals)
end
