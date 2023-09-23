
Base.@kwdef struct TournamentSelector <: Selector
    μ::Int # number of parents to select
    tournament_size::Int # tournament size
    selection_func::Function = argmax # function to select the winner of the tournament
end

function(s::TournamentSelector)(
    rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, ScalarFitnessEval}
)
    fitnesses = map(i -> evals[i].fitness, pop) 
    parent_idxs = Array{Int}(undef, s.μ)
    for i in 1:s.μ
        tournament_idxs = sample(rng, 1:length(pop), s.tournament_size, replace=false)
        parent_idxs[i] = tidxs[s.selection_func(fitnesses[tournament_idxs])]
    end
    pop[parent_idxs]
end
