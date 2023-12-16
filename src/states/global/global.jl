module Global

export GlobalState

using Random: AbstractRNG
using ...Counters: Counter
using ...Abstract: Experiment

mutable struct GlobalState
    id::String
    trial::Int
    n_generations::Int
    generation::Int
    rng::AbstractRNG
    individual_id_counter::Counter
    gene_id_counter::Counter
    evaluation_time::Float64
    last_reproduction_time::Float64
    experiment::Experiment
end



end