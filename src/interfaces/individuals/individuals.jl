export create_individuals
export convert_to_dict, create_from_dict

using ..Abstract

function create_individuals(
    individual_creator::IndividualCreator, 
    n_individuals::Int, 
    reproducer::Reproducer, 
    state::State
)
    individual_creator = typeof(individual_creator)
    n_individuals = typeof(n_individuals)
    reproducer = typeof(reproducer)
    state = typeof(state)
    error("create_individuals not implemented for $individual_creator, $reproducer, $state")
end

function convert_to_dict(individual::Individual)
    individual = typeof(individual)
    error("convert_to_dict not implemented for $individual")
end

function create_from_dict(individual_creator::IndividualCreator, dict::Dict, state::State)
    individual_creator = typeof(individual_creator)
    dict = typeof(dict)
    state = typeof(state)
    error("create_from_dict not implemented for $individual_creator, $dict, $state")
end