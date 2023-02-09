export Outcome
export getscore

struct Outcome{R <: Result, O <: Observation}
    recipe::Recipe
    results::Set{R}
    obs::O
end

function Outcome(recipe::Recipe, results::Set{<:Result})
    Outcome(recipe, results, NullObs())
end

function Outcome(recipe::Recipe, r1::Result, r2::Result)
    Outcome(recipe, Set([r1, r2]), NullObs())
end

function Outcome(recipe::Recipe, r1::Result, r2::Result, obs::Observation)
    Outcome(recipe, Set([r1, r2]), obs)
end

function getscore(ikey::IndivKey, outcome::Outcome)
    rdict = Dict(ikey => r for r in outcome.results)
    rdict[ikey].score
end

function getscore(spkey::Symbol, iid::Real, outcome::Outcome)
    getscore(IndivKey(spkey, iid), outcome)
end