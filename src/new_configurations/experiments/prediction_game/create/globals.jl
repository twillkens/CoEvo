export get_n_generations, get_n_workers, get_trial, make_random_number_generator
export make_performer, get_seed

import ...GlobalConfigurations: make_random_number_generator, make_performer
import ....Abstract.States: get_n_generations, get_n_workers, get_trial, get_seed


get_n_generations(
    config::PredictionGameExperimentConfiguration
) = get_n_generations(config.globals)

get_n_workers(
    config::PredictionGameExperimentConfiguration
) = get_n_workers(config.globals)

get_trial(
    config::PredictionGameExperimentConfiguration
) = get_trial(config.globals)

get_seed(
    config::PredictionGameExperimentConfiguration
) = get_seed(config.globals)

function make_random_number_generator(
    config::PredictionGameExperimentConfiguration
)
    return make_random_number_generator(config.globals)
end

make_performer(
    config::PredictionGameExperimentConfiguration
) = make_performer(config.globals)