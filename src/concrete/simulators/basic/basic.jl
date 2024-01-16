module Basic

export BasicSimulator

import ....Interfaces: simulate
using ....Abstract
using ....Interfaces

Base.@kwdef struct BasicSimulator{
    I <: Interaction,
    M <: MatchMaker,
    J <: JobCreator,
    P <: Performer,
} <: Simulator
    interactions::Vector{I}
    matchmaker::M
    job_creator::J
    performer::P
end

function simulate(simulator::BasicSimulator, ecosystem::Ecosystem, state::State)
    jobs = create_jobs(simulator.job_creator, ecosystem, state)
    results = perform(simulator.performer, jobs)
    return results 
end

end