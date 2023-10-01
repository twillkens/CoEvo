module Interact

export interact

using ...Environments.Abstract: Environment
using ...Interactions.Observers.Abstract: Observer
using ...Interactions.Observers.Interfaces: create_observation
using ...Environments.Interfaces: next!, get_outcome_set, is_active, observe!

using ....Ecosystems.Interactions.Results: Result

observe!(env::Environment, observers::Vector{<:Observer}) = [
   observe!(env, observer) for observer in observers
]
function interact(
    interaction_id::String,
    indiv_ids::Vector{Int},
    environment::Environment,
    observers::Vector{<:Observer},
)
    observe!(environment, observers)
    while is_active(environment)
        next!(environment)
        observe!(environment, observers)
    end
    outcome_set = get_outcome_set(environment)
    observations = [create_observation(observer) for observer in observers]
    result = Result(interaction_id, indiv_ids, outcome_set, observations)
    return result
end

end
