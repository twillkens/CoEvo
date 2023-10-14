module Methods

using .....Metrics.Abstract: Metric
using .....Metrics.Concrete.Common: AbsoluteError
using .....Metrics.Concrete.Evaluations: TestBasedFitness, AllSpeciesFitness
using .....Metrics.Concrete.Genotypes: GenotypeSum, GenotypeSize
using .....Measurements.Abstract: Measurement
using .....Ecosystems.Interactions.Observers.Abstract: Observation
using .....Measurements.Types: BasicStatisticalMeasurement, GroupStatisticalMeasurement
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Species.Evaluators.Types.ScalarFitness: ScalarFitnessEvaluation
using .....Ecosystems.Species.Evaluators.Types.NSGAII: NSGAIIEvaluation
using .....Ecosystems.Species.Abstract: AbstractSpecies
using .....Ecosystems.Interactions.Abstract: Interaction
using ....Reporters.Abstract: Reporter
using ...Basic: BasicReport, BasicReporter
using .....Metrics.Concrete.Common: AllSpeciesIdentity
using .....Measurements.Types: AllSpeciesMeasurement


import ....Reporters.Interfaces: create_report, measure
using .....Species.Genotypes.Interfaces: get_size, minimize

#function get_size(genotype::GeneticProgramGenotype)
#    root = get_node(genotype, genotype.root_id)
#    children = get_child_nodes(genotype, root)
#    return length(children) + 1
#end


function measure(
    reporter::Reporter{GenotypeSize},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [reporter.metric.minimize ? get_size(minimize(individual.geno)) : get_size(individual.geno) 
            for individual in values(species.pop)]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{GenotypeSum},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [sum(individual.geno.genes) for individual in values(species.pop)]
        ) 
        for species in keys(species_evaluations)
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{AbsoluteError},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    evaluation = filter(
        species_evaluation -> species_evaluation[1].id == "Subjects", 
        collect(species_evaluations)
    )[1][2]
    measurement = BasicStatisticalMeasurement(evaluation.outcome_sums)
    return measurement
end

function measure(
    ::Reporter{AllSpeciesFitness},
    species_evaluations::Dict{<:AbstractSpecies, NSGAIIEvaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [record.fitness for record in evaluation.disco_records]
        ) 
        for (species, evaluation) in species_evaluations
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{AllSpeciesFitness},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            collect(values(evaluation.fitnesses))
        ) 
        for (species, evaluation) in species_evaluations
            if typeof(evaluation) == ScalarFitnessEvaluation
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{AllSpeciesIdentity},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species = Dict(species.id => species for species in keys(species_evaluations))
    measurement = AllSpeciesMeasurement(species)
    return measurement
end


end