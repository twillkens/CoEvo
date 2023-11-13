function measure(metric::GlobalStateMetric, state::BasicCoevolutionaryState)
    base_path = "global_state"
    measurements = [
        BasicMeasurement(
            metric, "$base_path/rng_state", string(state.random_number_generator.state)
        ),
        BasicMeasurement(
            metric, 
            "$base_path/individual_id_counter_state", 
            state.individual_id_counter.current_value
        ),
        BasicMeasurement(
            metric, "$base_path/gene_id_counter_state", state.gene_id_counter.current_value
        )
    ]
    return measurements
end

function measure(metric::RuntimeMetric, state::BasicCoevolutionaryState)
    base_path = "runtime"
    measurements = [
        BasicMeasurement(
            metric, "$base_path/last_reproduction_time", state.last_reproduction_time
        ),
        BasicMeasurement(metric, "$base_path/evaluation_time", state.evaluation_time)
    ]
    return measurements
end

function measure(metric::SpeciesMetric, state::BasicCoevolutionaryState)
    all_species = state.species
    measurements = measure(metric, all_species)
    return measurements
end

function measure(
    metric::StatisticalSpeciesMetric{<:EvaluationMetric}, state::BasicCoevolutionaryState
)
    evaluations = state.evaluations
    measurements = measure(metric, evaluations)
    return measurements
end
