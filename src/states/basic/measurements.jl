function measure(metric::GenotypeSize,state::State)
    species_evaluations = Dict(
        species => evaluation for (species, evaluation) in zip(state.species, state.evaluations)
    )

    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [
                metric.minimize ? 
                    get_size(minimize(individual.genotype)) : get_size(individual.genotype) 
                for individual in values(species.population)
            ]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(::GenotypeSum, state::State)
    species_evaluations = Dict(
        species => evaluation for (species, evaluation) in zip(state.species, state.evaluations)
    )

    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [sum(individual.genotype.genes) for individual in species.population]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(::AllSpeciesFitness, state::State)
    species_evaluations = Dict(
        species => evaluation for (species, evaluation) in zip(state.species, state.evaluations)
    )

    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [record.fitness for record in evaluation.records]
        ) 
        for (species, evaluation) in species_evaluations
            if typeof(evaluation) != NullEvaluation
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(::AllSpeciesIdentity, state::State)
    species = Dict(species.id => species for species in state.species)
    measurement = AllSpeciesMeasurement(species)
    return measurement
end


# TODO: Refactor this to use the new `measure` interface.
# function measure(
#     ::Reporter{AbsoluteError},
#     state::CoevolutionaryState
# )
#     evaluation = filter(
#         species_evaluation -> species_evaluation[1].id == "Subjects", 
#         collect(
#             Dict(
#                 species => evaluation 
#                 for (species, evaluation) in zip(state.species, state.evaluations)
#             )
#         )
#     )[1][2]
#     measurement = BasicStatisticalMeasurement(evaluation.outcome_sums)
#     return measurement
# end
