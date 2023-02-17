export Species
export allindivs

struct Species{I <: Individual, P <: PhenoConfig}
    spid::Symbol
    phenocfg::P
    pop::Dict{IndivKey, I}
    children::Dict{IndivKey, I}
end

function allindivs(sp::Species)
    merge(sp.pop, sp.children)
end

function Species(spid::Symbol, phenocfg::PhenoConfig, pop::Dict{IndivKey, I}) where {I <: Individual}
    Species(spid, phenocfg, pop, Dict{IndivKey, I}())
end

function Species(
    spid::Symbol, phenocfg::PhenoConfig, pop::Dict{IndivKey, I}, ::Dict) where {I <: Individual
}
    Species(spid, phenocfg, pop, Dict{IndivKey, I}())
end


function Species(
    spid::Symbol, phenocfg::PhenoConfig,
    pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    Species(spid, phenocfg,
        Dict(indiv.ikey => indiv for indiv in pop),
        Dict(indiv.ikey => indiv for indiv in children))
end

function Species(spid::Symbol, phenocfg::PhenoConfig, pop::Vector{I}) where {I <: Individual}
    Species(spid, phenocfg, Dict(indiv.ikey => indiv for indiv in pop), Dict{IndivKey, I}())
end
