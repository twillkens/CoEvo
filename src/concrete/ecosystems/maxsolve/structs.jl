export MaxSolveSpecies, MaxSolveEcosystem, MaxSolveSpeciesParameters, MaxSolveEcosystemCreator
export DiscoRecord, DiscoEvaluation
export MaxSolveEvaluation, EvolutionStrategyParameters, DodoParameters
export EcosystemScoreParameters, StandardParameters, SCORE_PARAMS

using ....Abstract
using ....Interfaces
import ....Interfaces: make_all_matches, update_species!
using Random
using StatsBase
using ...Ecosystems.Simple: SimpleEcosystem
using ...Species.Basic: BasicSpecies
using ...Recombiners.Clone: CloneRecombiner
using ....Interfaces
using ....Abstract
using ...Matrices.Outcome
using ...Matches.Basic

Base.@kwdef mutable struct MaxSolveSpecies{I <: Individual} <: AbstractSpecies
    id::String
    population::Vector{I}
    children::Vector{I}
    archive::Vector{I}
    retirees::Vector{I}
    active::Vector{I}
end


function get_all_individuals(species::MaxSolveSpecies)
    return unique([species.population ; species.children ; species.archive ; species.retirees])
end

function Base.getindex(species::MaxSolveSpecies, individual_id::Int)
    all_individuals = get_all_individuals(species)
    individual = find_by_id(all_individuals, individual_id)
    if individual === nothing
        error("individual_id = $individual_id not found in species")
    end
    return individual
end

Base.@kwdef mutable struct MaxSolveEcosystem{S <: MaxSolveSpecies} <: Ecosystem
    id::Int
    learners::S
    tests::S
end

function get_all_individuals(ecosystem::MaxSolveEcosystem)
    return unique([get_all_individuals(ecosystem.learners) ; get_all_individuals(ecosystem.tests)])
end

Base.@kwdef struct MaxSolveSpeciesParameters
    n_population::Int
    n_parents::Int
    n_children::Int
    max_archive_size::Int
    max_retiree_size::Int
    max_active_archive::Int
    max_active_retirees::Int
end

Base.@kwdef struct MaxSolveEcosystemCreator <: EcosystemCreator 
    id::Int = 1
    learners = MaxSolveSpeciesParameters()
    tests = MaxSolveSpeciesParameters()
    algorithm::String = "standard"
end

#Base.@kwdef mutable struct NewDodoRecord{I <: Individual} <: Record
#    id::Int = 0
#    individual::I
#    raw_outcomes::Vector{Float64} = Float64[]
#    filtered_outcomes::Vector{Float64} = Float64[]
#    outcomes::Vector{Float64} = Float64[]
#    rank::Int = 0
#    crowding::Float64 = 0.0
#    dom_count::Int = 0
#    dom_list::Vector{Int} = Int[]
#end
#
#Base.@kwdef struct NewDodoEvaluation{
#    R <: NewDodoRecord, M1 <: OutcomeMatrix, M2 <: OutcomeMatrix, M3 <: OutcomeMatrix
#} <: Evaluation
#    id::String
#    cluster_leader_ids::Vector{Int}
#    farthest_first_ids::Vector{Int}
#    raw_matrix::M1
#    filtered_matrix::M2
#    matrix::M3
#    records::Vector{R}
#end

Base.@kwdef mutable struct DiscoRecord <: Record
    id::Int = 0
    raw_outcomes::Vector{Float64} = Float64[]
    filtered_outcomes::Vector{Float64} = Float64[]
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
    cluster::Int = 0
end

Base.@kwdef struct DiscoEvaluation{
    M1 <: OutcomeMatrix, M2 <: OutcomeMatrix, M3 <: OutcomeMatrix, R <: DiscoRecord
} <: Evaluation
    id::String
    raw_matrix::M1
    filtered_matrix::M2
    matrix::M3
    records::Vector{R}
end

function Base.getindex(ecosystem::MaxSolveEcosystem, individual_id::Int)
    all_individuals = get_all_individuals(ecosystem)
    #println("all_ids = ", [individual.id for individual in all_individuals])
    individual = find_by_id(all_individuals, individual_id)
    if individual === nothing
        error("individual_id = $individual_id not found in ecosystem")
    end
    return individual
end

struct MaxSolveEvaluation{T <: OutcomeMatrix, U <: OutcomeMatrix} <: Evaluation
    id::String
    payoff_matrix::T
    distinction_matrix::U
end

Base.@kwdef struct ScoreParameters
    zero_out_duplicate_rows::Bool
    competitive_sharing::Bool
    weight::Float64
end

abstract type SpeciesScoreParameters end

Base.@kwdef struct EvolutionStrategyParameters <: SpeciesScoreParameters
    outcomes::ScoreParameters
    distinctions::ScoreParameters
end

Base.@kwdef struct DiscoParameters <: SpeciesScoreParameters
    use_outcomes::Bool = true
    n_clusters::Int = 5
end

Base.@kwdef struct DodoParameters <: SpeciesScoreParameters
    outcomes::ScoreParameters
    distinctions::ScoreParameters
    n_elites::Int = 3
end

Base.@kwdef struct EcosystemScoreParameters{
    L <: SpeciesScoreParameters, T <: SpeciesScoreParameters
}
    learners::L
    tests::T
end

Base.@kwdef struct StandardParameters{
    L <: SpeciesScoreParameters, T <: SpeciesScoreParameters
}
    learners::L
    tests::T
end

SCORE_PARAMS = Dict(
    "standard" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        )
    ),
    "cel" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 1.0), 
            distinctions = ScoreParameters(false, false, 0.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(false, false, 1.0)
        )
    ),
    "advanced" => EcosystemScoreParameters(
        learners = EvolutionStrategyParameters(
            outcomes = ScoreParameters(true, true, 3.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        ),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(true, true, 3.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        )
    ), 
    "disco" => EcosystemScoreParameters(
        learners = DiscoParameters(),
        tests = EvolutionStrategyParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(false, false, 1.0)
        )
    ),
    "dodo" => EcosystemScoreParameters(
        learners = DiscoParameters(),
        tests = DodoParameters(
            outcomes = ScoreParameters(false, false, 0.0), 
            distinctions = ScoreParameters(true, true, 1.0)
        )
    )
)