module Configurations

export CircleExperiment

include("circle_experiment/circle_experiment.jl")
using .CircleExperiment: CircleExperiment

end