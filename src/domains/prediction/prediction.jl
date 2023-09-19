
module ContinuousPredictionGame
using ...Base.Common
using ...Base.Indivs.GP: TapeReaderGPPheno, get_tape_copy, reset!, add_value!, spin
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
    tape1::Vector{Float64}
    tape2::Vector{Float64}
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
    oid::Symbol, domain::ContinuousPredictionGameDomain, ::ObsConfig,
    p1::TapeReaderGPPheno, p2::TapeReaderGPPheno
)
    # Reset the tapes to their initial state, a vector of length 1 containing 0.0.
    reset!(p1)
    reset!(p2)
    # Initial position is 0.0 radians.
    pos1, pos2 = 0.0, 0.0
    positions1, positions2 = [pos1], [pos2]
    for _ in 1:domain.episode_len - 1
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
    max_dist = π * domain.episode_len
    dist_score = sum(distances) / max_dist
    if domain.type == "comp"
        Outcome(oid, p1 => 1 - dist_score, p2 => dist_score, obs)
    elseif domain.type == "coop_match"
        Outcome(oid, p1 => 1 - dist_score, p2 => 1 - dist_score, obs)
    elseif domain.type == "coop_diff"
        Outcome(oid, p1 => dist_score, p2 => dist_score, obs)
    else
        throw(ErrorException("Unknown domain type: $(domain.type)"))
    end
end

end