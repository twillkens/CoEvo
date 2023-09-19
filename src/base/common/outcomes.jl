export Outcome
export getscore

struct Outcome{R <: Real, O <: Observation}
    oid::Symbol
    rdict::Dict{IndivKey, Pair{TestKey, R}}
    obs::O
end

function Base.show(io::IO, o::Outcome)
    print(io, "Outcome($(o.oid)")
    for (ikey, pair) in o.rdict
        print(io, "\n\t$ikey => $(pair.first) => $(pair.second)")
    end
    print(io, "\n$(o.obs)")
end

function Outcome(oid::Symbol, rdict::Dict{IndivKey, Pair{TestKey, <:Real}})
    Outcome(oid, rdict, NullObs())
end

function Outcome(oid::Symbol, pr1::Pair{<:Phenotype, <:Real}, pr2::Pair{<:Phenotype, <:Real})
    Outcome(
        oid,
        Dict(
            pr1.first.ikey => TestKey(oid, pr2.first.ikey) => pr1.second,
            pr2.first.ikey => TestKey(oid, pr1.first.ikey) => pr2.second
        ),
        NullObs()
    )
end

function Outcome(
    oid::Symbol,
    pr1::Pair{<:Phenotype, <:Real}, pr2::Pair{<:Phenotype, <:Real},
    obs::Observation
)
    Outcome(
        oid,
        Dict(
            pr1.first.ikey => TestKey(oid, pr2.first.ikey) => pr1.second,
            pr2.first.ikey => TestKey(oid, pr1.first.ikey) => pr2.second),
        obs
    )
end

function getscore(ikey::IndivKey, o::Outcome)
    o.rdict[ikey].second
end

function getscore(spkey::Symbol, iid::Real, o::Outcome)
    getscore(IndivKey(spkey, iid), o)
end