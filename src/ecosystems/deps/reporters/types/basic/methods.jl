module Methods

using DataStructures: OrderedDict
using .....Metrics.Abstract: Metric
using .....Metrics.Outcomes.Types.Generic: AbsoluteError
using .....Metrics.Evaluations.Types: TestBasedFitness, AllSpeciesFitness
using .....Metrics.Species.Types: GenotypeSum, GenotypeSize
using .....Measurements.Abstract: Measurement
using .....Measurements: BasicStatisticalMeasurement, GroupStatisticalMeasurement
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Species.Evaluators.Types.ScalarFitness: ScalarFitnessEvaluation
using .....Ecosystems.Species.Abstract: AbstractSpecies
using .....Ecosystems.Interactions.Abstract: Interaction
using .....Ecosystems.Interactions.Observers.Abstract: Observation
using ....Reporters.Abstract: Reporter
using .....Species.Genotypes.GeneticPrograms: GeneticProgramGenotype, ExpressionNodeGene
using .....Species.Genotypes.GeneticPrograms.Methods.Traverse: get_node, get_child_nodes
using ...Basic: BasicReport, BasicReporter

import ....Reporters.Interfaces: create_report, measure

function get_size(genotype::GeneticProgramGenotype)
    root = get_node(genotype, genotype.root_id)
    children = get_child_nodes(genotype, root)
    return length(children) + 1
end


function measure(
    ::Reporter{GenotypeSize},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            [get_size(individual.geno) for individual in values(species.pop)]
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



function create_report(
    reporter::BasicReporter,
    gen::Int,
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)
    to_print = reporter.print_interval > 0 && gen % reporter.print_interval == 0
    to_save = reporter.save_interval > 0 && gen % reporter.save_interval == 0
    measurement = measure(reporter, species_evaluations, observations)
    report = BasicReport(
        to_print,
        to_save,
        reporter.metric,
        measurement
    )
    return report
end

end