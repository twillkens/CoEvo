module LinguisticPredictionGame

export LinguisticPredictionGameEnvironmentCreator
export LingusticPredictionGameEnvironment

using ....Domains.Abstract: Domain
using ....Domains.Concrete: LinguisticPredictionGameDomain
using ....Domains.Interfaces: measure
using ....Environments.Abstract: Environment, EnvironmentCreator
using .....Species.Phenotypes.Abstract: Phenotype
using .....Species.Phenotypes.FiniteStateMachines: FiniteStateMachinePhenotype 
using .....Species.Phenotypes.Interfaces: act!

import ....Environments.Interfaces: get_outcome_set, create_environment, is_active, next!

Base.@kwdef struct LinguisticPredictionGameEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D}
    domain::D
end

Base.@kwdef mutable struct LingusticPredictionGameEnvironment{D, P <: Phenotype, T} <: Environment{D}
    domain::D
    phenotypes::Vector{P}
    timestep::Int
    loop_start::Int
    state1::T
    state2::T
    bit1::Bool
    bit2::Bool
    states1::Vector{T}
    states2::Vector{T}
    bits1::Vector{Bool}
    bits2::Vector{Bool}
    state_pair_log::Dict{Tuple{T, T}, Int} = Dict{Tuple{T, T}, Int}()
end

function create_environment(
    environment_creator::LinguisticPredictionGameEnvironmentCreator{D},
    phenotypes::Vector{FiniteStateMachinePhenotype{T}}
) where {D <: Domain, T}
    fsm_A, fsm_B = phenotypes
    state1, bit1 = fsm_A.start
    state2, bit2 = fsm_B.start
    state_pair_log = Dict((state1, state2) => 1)
    return LingusticPredictionGameEnvironment(
        domain = environment_creator.domain,
        phenotypes = phenotypes,
        timestep = 1,
        loop_start = -1,
        state1 = state1,
        state2 = state2,
        bit1 = bit1,
        bit2 = bit2,
        states1 = T[],
        states2 = T[],
        bits1 = Bool[],
        bits2 = Bool[],
        state_pair_log = state_pair_log
    )
end

function is_active(environment::LingusticPredictionGameEnvironment)
    if length(environment.states1) < 2
        return true
    end
    last_state1 = environment.state1
    last_state2 = environment.state2
    loop_entered = (last_state1, last_state2) in keys(environment.state_pair_log)
    if loop_entered
        environment.loop_start = environment.state_pair_log[(last_state1, last_state2)]
    end
    return !loop_entered
end

function update_state_vectors!(environment::LingusticPredictionGameEnvironment)
    push!(environment.states1, environment.state1)
    push!(environment.states2, environment.state2)
    push!(environment.bits1, environment.bit1)
    push!(environment.bits2, environment.bit2)
end

function next!(
    environment::LingusticPredictionGameEnvironment{D, <:Phenotype}
) where {D <: LinguisticPredictionGameDomain}
    fsm1, fsm2 = environment.phenotypes
    state1, state2 = environment.state1, environment.state2
    bit1, bit2 = environment.bit1, environment.bit2
    update_state_vectors!(environment)
    logkey = (state1, state2)
    push!(environment.state_pair_log, logkey => environment.timestep)
    environment.state1, environment.bit1 = act!(fsm1, state1, bit2)
    environment.state2, environment.bit2 = act!(fsm2, state2, bit1)
    environment.timestep += 1
end


function get_outcome_set(
    environment::LingusticPredictionGameEnvironment{D, <:Phenotype}
) where {D <: LinguisticPredictionGameDomain}
    update_state_vectors!(environment)
    bits1 = environment.bits1[environment.loop_start:end - 1]
    bits2 = environment.bits2[environment.loop_start:end - 1]
    matches = [bit1 == bit2 for (bit1, bit2) in zip(bits1, bits2)]
    distance_score = 1 - (sum(matches) / length(matches))
    outcome_set = measure(environment.domain, distance_score)
    return outcome_set
end

end