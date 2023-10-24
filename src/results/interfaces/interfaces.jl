module Interfaces

export get_individual_outcomes, get_observations

using ..Results.Abstract: Result

function get_individual_outcomes(results::Vector{Result})
    throw(ErrorException("`get_individual_outcomes` not implemented for $(typeof(results))"))
end

function get_observations(results::Vector{Result})
    throw(ErrorException("`get_observations` not implemented for $(typeof(results))"))
end

end