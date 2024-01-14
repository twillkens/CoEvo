module Basic

export BasicSimulator

using ....Abstract

Base.@kwdef struct BasicSimulator{
    I <: Interaction,
    M <: MatchMaker,
    J <: JobCreator,
    P <: Performer,
    R <: Result
} <: Simulator
    interactions::Vector{I}
    matchmaker::M
    job_creator::J
    performer::P
end

end