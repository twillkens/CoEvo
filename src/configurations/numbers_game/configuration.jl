using Base: @kwdef


@kwdef mutable struct NumbersGameConfiguration <: Configuration
    trial::Int = 1
    seed::Int = 777
    reproduction_method::String = "disco"
    outcome_metric::String = "Control"
    rng::Union{AbstractRNG, Nothing} = nothing
    noise_standard_deviation::Float64 = 0.1
    individual_id_counter_state::Int = 1
    gene_id_counter_state::Int = 1
    n_workers::Int = 1
    n_population::Int = 50
    n_children::Int = n_population
    tournament_size::Int = 3
    max_clusters::Int = 5
    cohorts::Vector{String} = ["population", "children"]
    report_type::String = "silent_test"
end
