
module ContinuousPredictionGame
using ...Base.Common
using ...Base.Indivs.GP: TapeReaderGPPheno, get_tape_copy, reset!, add_value!, spin
using ...Base.Indivs.GP: GPPheno
import ...Base.Jobs: stir
export ContinuousPredictionGameDomain, stir, PredictionGameObservation

Base.@kwdef struct ContinuousPredictionGameDomain <: Domain
    episode_len::Int = 10
    type::String = "comp"
end

function radianshift(x::Real)
    x - (floor(x / 2π) * 2π)
end

struct PredictionGameObservation <: Observation
    oid::Symbol
    pos1::Vector{Float64}
    pos2::Vector{Float64}
    dist1::Vector{Float64}
    dist2::Vector{Float64}
end

function Base.show(io::IO, obs::PredictionGameObservation)
    print(io, "PredictionGameObservation($(obs.oid)\n")
    v1, v2 = round.(obs.tape1, digits=2), round.(obs.tape2, digits=2)
    print(io, "tape1: $(v1)\n")
    print(io, "tape2: $(v2)\n")
end

function PredictionGameObservation(
    oid::Symbol, p1::TapeReaderGPPheno, p2::TapeReaderGPPheno
)
    PredictionGameObservation(oid, get_tape_copy(p1), get_tape_copy(p2))
end

function stir(
    oid::Symbol, env::ContinuousPredictionGameDomain, ::ObsConfig,
    p1::TapeReaderGPPheno, p2::TapeReaderGPPheno
)
    # Reset the tapes to their initial state, a vector of length 1 containing 0.0.
    reset!(p1)
    reset!(p2)
    # Initial position is 0.0 radians.
    pos1, pos2 = 0.0, 0.0
    positions1, positions2 = [pos1], [pos2]
    for _ in 1:env.episode_len - 1
        # Get the current value from the tape, and move the head back one position.
        move1, move2 = spin(p1), spin(p2)
        pos1, pos2 = radianshift(pos1 + move1), radianshift(pos2 + move2)
        diff1, diff2 = radianshift(pos2 - pos1), radianshift(pos1 - pos2)
        add_value!(p1, diff1)
        add_value!(p2, diff2)
        push!(positions1, pos1)
        push!(positions2, pos2)
    end
    obs = PredictionGameObservation(oid, p1, p2)
    distances = [min(diff1, diff2) for (diff1, diff2) in zip(p1.reader.tape, p2.reader.tape)]
    max_dist = π * env.episode_len
    dist_score = sum(distances) / max_dist
    if env.type == "comp"
        Outcome(oid, p1 => 1 - dist_score, p2 => dist_score, obs)
    elseif env.type == "coop_match"
        Outcome(oid, p1 => 1 - dist_score, p2 => 1 - dist_score, obs)
    elseif env.type == "coop_diff"
        Outcome(oid, p1 => dist_score, p2 => dist_score, obs)
    else
        throw(ErrorException("Unknown env type: $(env.type)"))
    end
end



function stir(
    oid::Symbol, env::ContinuousPredictionGameDomain, ::ObsConfig,
    p1::GPPheno, p2::GPPheno
)
    if env.type == "ctrl"
        return Outcome(oid, p1 => 1.0, p2 => 1.0, 
            PredictionGameObservation(oid, Float64[], Float64[], Float64[], Float64[])
        )
    end
    # Initial position is 0.0 radians.
    pos1, pos2 = 0.0, 0.0
    positions1, positions2 = [pos1], [pos2]
    dists1, dists2 = Float64[0.0], [0.0]
    for _ in 1:env.episode_len
        # Get the current value from the tape, and move the head back one position.
        move1, move2 = spin(p1, dists1), spin(p2, dists2)
        pos1, pos2 = radianshift(pos1 + move1), radianshift(pos2 + move2)
        push!(positions1, pos1)
        push!(positions2, pos2)
        diff1, diff2 = radianshift(pos2 - pos1), radianshift(pos1 - pos2)
        push!(dists1, diff1)
        push!(dists2, diff2)
    end
    obs = PredictionGameObservation(oid, positions1, positions2, dists1, dists2)
    distances = [
        min(diff1, diff2) for (diff1, diff2) in zip(dists1, dists2)
    ][2:end]
    dist_score = sum(distances) / (π * length(distances))
    if env.type == "comp"
        Outcome(oid, p1 => dist_score, p2 => 1 - dist_score, obs)
    elseif env.type == "coop_match"
        Outcome(oid, p1 => 1 - dist_score, p2 => 1 - dist_score, obs)
    elseif env.type == "coop_diff"
        Outcome(oid, p1 => dist_score, p2 => dist_score, obs)
    elseif env.type == "ctrl"
        Outcome(oid, p1 => 1.0, p2 => 1.0, obs)
    else
        throw(ErrorException("Unknown env type: $(env.type)"))
    end
end

end