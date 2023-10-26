
@kwdef mutable struct NumbersGameConfiguration <: Configuration
    trial::Int = 1
    seed::Int = 777
    reproduction_method::Symbol = :disco
    outcome_metric::Symbol = :Control
    random_number_generator::Union{AbstractRNG, Nothing} = nothing
    noise_standard_deviation::Float64 = 0.1
    individual_id_counter_state::Int = 1
    gene_id_counter_state::Int = 1
    n_workers::Int = 1
    n_population::Int = 50
    n_children::Int = n_population
    tournament_size::Int = 3
    max_clusters::Int = 5
    cohorts::Vector{Symbol} = [:population, :children]
    report_type::Symbol = :silent_test
end
