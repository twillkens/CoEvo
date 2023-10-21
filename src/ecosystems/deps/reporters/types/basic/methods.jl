module Methods

using .....Metrics.Abstract: Metric
using .....Metrics.Concrete.Common: AbsoluteError
using .....Metrics.Concrete.Evaluations: TestBasedFitness, AllSpeciesFitness
using .....Metrics.Concrete.Genotypes: GenotypeSum, GenotypeSize
using .....Measurements.Abstract: Measurement
using .....Measurements.Types: BasicStatisticalMeasurement, GroupStatisticalMeasurement
using .....Ecosystems.Species.Evaluators.Types.Null: NullEvaluation
using ....Reporters.Abstract: Reporter
using .....Metrics.Concrete.Common: AllSpeciesIdentity
using .....Measurements.Types: AllSpeciesMeasurement
using .....Ecosystems.States.Abstract: CoevolutionaryState


import ....Reporters.Interfaces: create_report, measure
using .....Species.Genotypes.Interfaces: get_size, minimize

#function get_size(genotype::GeneticProgramGenotype)
#    root = get_node(genotype, genotype.root_id)
#    children = get_child_nodes(genotype, root)
#    return length(children) + 1
#end


function measure(
    reporter::Reporter{GenotypeSize},
    state::CoevolutionaryState
)
    species_evaluations = Dict(
        species => evaluation for (species, evaluation) in zip(state.species, state.evaluations)
    )

    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [
                reporter.metric.minimize ? 
                    get_size(minimize(individual.geno)) : get_size(individual.geno) 
                for individual in values(species.population)
            ]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{GenotypeSum},
    state::CoevolutionaryState
)
    species_evaluations = Dict(
        species => evaluation for (species, evaluation) in zip(state.species, state.evaluations)
    )

    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [sum(individual.geno.genes) for individual in species.population]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{AllSpeciesFitness},
    state::CoevolutionaryState
)
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

function measure(
    ::Reporter{AllSpeciesIdentity},
    state::CoevolutionaryState
)
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


end