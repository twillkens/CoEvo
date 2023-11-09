function measure(::GlobalStateMetric, state::BasicCoevolutionaryState)
    measurement = BasicGroupMeasurement(
        name = "global_state",
        measurements = [
            BasicMeasurement("rng_state", string(state.random_number_generator.state)),
            BasicMeasurement(
                "individual_id_counter_state", state.individual_id_counter.current_value
            ),
            BasicMeasurement("gene_id_counter_state", state.gene_id_counter.current_value)
        ]
    )
    return measurement
end

function measure(::RuntimeMetric, state::BasicCoevolutionaryState)
    measurement = BasicGroupMeasurement(
        name = "runtime",
        measurements = [
            BasicMeasurement("last_reproduction_time", state.last_reproduction_time),
            BasicMeasurement("evaluation_time", state.evaluation_time)
        ]
    )
    return measurement
end


function measure(metric::EvaluationMetric, state::BasicCoevolutionaryState)
    evaluations = state.evaluations
    measurement = measure(metric, evaluations)
    return measurement
end


function measure(metric::SpeciesMetric, state::BasicCoevolutionaryState)
    all_species = state.species
    measurement = measure(metric, all_species)
    return measurement
end
