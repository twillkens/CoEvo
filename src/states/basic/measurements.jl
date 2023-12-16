function measure(metric::GlobalStateMetric, state::BasicCoevolutionaryState)
    base_path = "global_state"
    measurements = [
        BasicMeasurement(
            "$base_path/rng_state", string(state.rng.state)
        ),
        BasicMeasurement(
            "$base_path/individual_id_counter_state", 
            state.individual_id_counter.current_value
        ),
        BasicMeasurement(
            "$base_path/gene_id_counter_state", state.gene_id_counter.current_value
        )
    ]
    return measurements
end

function measure(metric::RuntimeMetric, state::BasicCoevolutionaryState)
    base_path = "runtime"
    measurements = [
        BasicMeasurement(
            "$base_path/last_reproduction_time", state.last_reproduction_time
        ),
        BasicMeasurement("$base_path/evaluation_time", state.evaluation_time)
    ]
    return measurements
end

function measure(metric::SpeciesMetric, state::BasicCoevolutionaryState)
    all_species = state.species
    measurements = measure(metric, all_species)
    return measurements
end

function measure(
    metric::AggregateSpeciesMetric{<:EvaluationMetric}, state::BasicCoevolutionaryState
)
    evaluations = state.evaluations
    measurements = measure(metric, evaluations)
    return measurements
end
