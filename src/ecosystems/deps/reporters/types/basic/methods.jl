module Methods

using DataStructures: OrderedDict
using .....Metrics.Abstract: Metric
using .....Metrics.Evaluations.Types: TestBasedFitness, AllSpeciesFitness
using .....Metrics.Species.Types: GenotypeSum, GenotypeSize
using .....Measurements.Abstract: Measurement
using .....Measurements: BasicStatisticalMeasurement, GroupStatisticalMeasurement
using .....Ecosystems.Species.Evaluators.Abstract: Evaluation
using .....Ecosystems.Species.Abstract: AbstractSpecies
using .....Ecosystems.Interactions.Abstract: Interaction
using .....Ecosystems.Interactions.Observers.Abstract: Observation
using  ....Reporters.Abstract: Reporter
using ...Basic: BasicReport, BasicReporter

import ....Reporters.Interfaces: create_report, measure



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
    ::Reporter{AllSpeciesFitness},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    ::Vector{<:Observation}
)
    species_measurements = Dict(
        species.id => BasicStatisticalMeasurement(
            collect(values(evaluation.fitnesses))
        ) 
        for (species, evaluation) in species_evaluations
    )
        
    measurement = GroupStatisticalMeasurement(species_measurements)
    return measurement
end

function measure(
    ::Reporter{TestBasedFitness},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
)
    subject_evaluations = filter(
        species_evaluation -> species_evaluation[1].id == "subjects", 
        collect(species_evaluations)
    )
    evaluation = subject_evaluations[1][2]
    fitnesses = collect(values(evaluation.fitnesses))
    measurement = BasicStatisticalMeasurement(fitnesses)
    return measurement
end

function measure(
    reporter::Reporter{TestBasedFitness},
    species_evaluations::Dict{<:AbstractSpecies, <:Evaluation},
    observations::Vector{<:Observation}
)
    measurement = measure(reporter, species_evaluations)
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