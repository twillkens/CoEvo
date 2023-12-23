module LinguisticPredictionGame

export LinguisticPredictionGameConfiguration

import ...GameConfigurations: make_environment_creator

using ...GameConfigurations: GameConfiguration
using ....Environments.LinguisticPredictionGame: LinguisticPredictionGameEnvironmentCreator
using ....Domains.PredictionGame: PredictionGameDomain
using ...TopologyConfigurations.Basic: BasicInteractionConfiguration

struct LinguisticPredictionGameConfiguration <: GameConfiguration
    id::String
end

function LinguisticPredictionGameConfiguration(;
    id::String = "linguistic_prediction_game", kwargs...
)
    configuration = LinguisticPredictionGameConfiguration(id = id)
    return configuration
end

function make_environment_creator(
    ::LinguisticPredictionGameConfiguration, setup::BasicInteractionConfiguration
)
    domain = PredictionGameDomain(setup.domain)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain = domain)
    return environment_creator
end

end