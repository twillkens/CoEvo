using ...Species.Individuals.Abstract: Individual
using ...Species.Evaluators.Abstract: Evaluation
using ..Metrics.Abstract: EvaluationMetric, GenotypeMetric

import .Abstract: create_report
"""
    function(reporter::BasicSpeciesReporter{<:EvaluationMetric})(
        gen::Int,
        species_id::String,
        cohort::String,
        indiv_evals::OrderedDict{<:Individual, <:Evaluation}
    )

Specialized function to generate a report when the metric is of type `EvaluationMetric`.

# Arguments
- `gen::Int`: Generation number.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `indiv_evals::OrderedDict{<:Individual, <:Evaluation}`: Ordered dictionary of individuals and their evaluations.

# Returns
- A `BasicSpeciesReport` instance containing the generated report details.
"""
function create_report(
    reporter::SpeciesReporter{<:EvaluationMetric}
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    report = create_report(reporter, gen, species_id, cohort, collect(values(indiv_evals)))
    return report
end

"""
    function(reporter::BasicSpeciesReporter{<:GenotypeMetric})(
        gen::Int,
        species_id::String,
        cohort::String,
        indiv_evals::OrderedDict{<:Individual, <:Evaluation}
    )

Specialized function to generate a report when the metric is of type `GenotypeMetric`.

# Arguments
- `gen::Int`: Generation number.
- `species_id::String`: ID of the species.
- `cohort::String`: Name/ID of the cohort.
- `indiv_evals::OrderedDict{<:Individual, <:Evaluation}`: Ordered dictionary of individuals and their evaluations.

# Returns
- A `BasicSpeciesReport` instance containing the generated report details.
"""

function create_report(
    reporter::SpeciesReporter{<:GenotypeMetric},
    gen::Int,
    species_id::String,
    cohort::String,
    indiv_evals::OrderedDict{<:Individual, <:Evaluation}
)
    genotypes = [indiv.geno for indiv in keys(indiv_evals)]
    report = create_report(reporter, gen, species_id, cohort, genotypes)
    return report
end