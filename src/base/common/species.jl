export Species
export allindivs

struct Species{I1 <: Individual, I2 <: Individual, P <: PhenoConfig}
    spid::Symbol
    phenocfg::P
    pop::Dict{IndivKey, I1}
    children::Dict{IndivKey, I2}
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
    pop::Vector{I1}, children::Vector{I2} 
) where {I1 <: Individual, I2 <: Individual}
    Species(spid, phenocfg,
        Dict{IndivKey, I1}(indiv.ikey => indiv for indiv in pop),
        Dict{IndivKey, I2}(indiv.ikey => indiv for indiv in children))
end

function Species(spid::Symbol, phenocfg::PhenoConfig, pop::Vector{I}) where {I <: Individual}
    Species(spid, phenocfg, Dict(indiv.ikey => indiv for indiv in pop), Dict{IndivKey, I}())
end
