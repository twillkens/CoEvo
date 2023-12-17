module States

export State, StateCreator, get_rng, get_gene_id_counter, get_individual_id_counter
export get_all_species, get_evaluations, get_evaluators, get_job_creator, get_performer
export get_reporters, get_archiver, get_generation, get_last_reproduction_time
export get_evaluation_time, get_trial, get_species_creators, get_species    
export get_individual_outcomes, get_observations, get_species, get_evaluation
export get_phenotype_creators, get_n_workers, get_interactions
export get_evaluator, get_species, get_evaluation, find_by_id, get_perfomer
export get_generation

abstract type State end
abstract type StateCreator end

get_rng(state::State) = state.rng
get_gene_id_counter(state::State) = state.gene_id_counter
get_individual_id_counter(state::State) = state.individual_id_counter
get_all_species(state::State) = state.all_species
get_evaluations(state::State) = state.evaluations
get_evaluators(state::State) = state.evaluators
get_job_creator(state::State) = state.job_creator
get_performer(state::State) = state.performer
get_reporters(state::State) = state.reporters
get_archiver(state::State) = state.archiver
get_generation(state::State) = state.generation
get_last_reproduction_time(state::State) = state.last_reproduction_time
get_evaluation_time(state::State) = state.evaluation_time
get_trial(state::State) = state.trial
get_species_creators(state::State) = state.species_creators
get_individual_outcomes(state::State) = state.individual_outcomes
get_observations(state::State) = state.observations
get_phenotype_creators(state::State) = state.phenotype_creators
get_n_workers(state::State) = state.n_workers
get_interactions(state::State) = state.interactions
get_perfomer(state::State) = state.performer


function find_by_id(collection::Vector{T}, id::I) where {T, I}
    filtered = filter(item -> item.id == id, collection)
    if length(filtered) == 0
        throw(ErrorException("Could not find item with id $id"))
    elseif length(filtered) > 1
        throw(ErrorException("Multiple items with id $id found"))
    else
        return first(filtered)
    end
end

function get_evaluator(state::State, id::String)
    evaluators = get_evaluators(state)
    evaluator = find_by_id(evaluators, id)
    return evaluator
end

function get_species(state::State, species_id::String)
    all_species = get_all_species(state)
    species = find_by_id(all_species, species_id)
    return species
end

function get_evaluation(state::State, evaluation_id::String)
    evaluations = get_evaluations(state)
    evaluation = find_by_id(evaluations, evaluation_id)
    return evaluation
end

end