export VSpawner

abstract type Individual end
abstract type GenoLog end
abstract type Gene end


@Base.kwdef mutable struct VSpawner{S <: VSelector, V <: Variator}
    key::String
    selector::S
    variator::V
    currid::Int
    μ::Int
    λ::Int
    comma::Bool
    n_elites::Int
end

struct VPop{I <: Individual, O <: Outcome} <: Population
    key::String
    indivs::Dict{String, I}
    parents::Dict{String, I}
    children::Dict{String, I}
end

function make_genokey(pop::VPop, childid::Int)
    string(pop.key, KEY_SPLIT_TOKEN, childid)
end

function(s::VSpawner)(gen::Int, pop::VPop,)
    elites, parents = s.selector(s.μ, s.comma, s.n_elites, pop)
    childids = [collect(range(s.currid, s.currid + (s.λ - s.n_elites)))]
    childkeys = [make_genokey(pop, childid) for childid in childids]
    s.currid += (s.λ - s.n_elites)
    children = merge(elites, s.variator(gen, childkeys, parents,))
    VPop(pop.key, merge(parents, children), parents, children)
end


function popkey(genokey::String)
    split(genokey, KEY_SPLIT_TOKEN)[1]
end

function popkey(geno::Genotype)
    split(geno.key, KEY_SPLIT_TOKEN)[1]
end

function assign_outcomes!(pops::Dict{String, VPop}, job_outcomes::Set{<:Outcome})
    for o in job_outcomes
        indiv = pops[popkey(o.genokey)].indivs[o.genokey]
        push!(indiv.outcomes, o)
    end
end

function(c::CoevConfig)(gen::Int, pops::Dict{String, VPop})
    jobs = c.job_cfg(c.orders, pops)
    job_outcomes = Set{Outcome}(jobs)
    assign_outcomes!(pops, job_outcomes)
    gen_group = JLD2.Group(c.jld2file, string(gen))
    gen_group["rng"] = copy(c.rng)
    [logger(gen_group, pops) for logger in c.loggers]
    newpops = [spawner(gen, pops[spawner.key]) for spawner in c.spawners]
    Dict([p.key => p for p in newpops])
end

struct ScoreOutcome <: Outcome
    mixn::Int
    genokey::String
    testkey::String
    role::Symbol
    score::Float64
end


# function make_records(genos::Set{<:Genotype}, outcomes::Set{ScalarOutcome}) 
#     odict = Dict{String, SortedDict{String, Float64}}()
#     for o in outcomes
#         for r in o.results
#             if r.key ∉ keys(odict)
#                 odict[r.key] = SortedDict(r.testkey => r.score)
#             else
#                 odict[r.key][r.testkey] = r.score
#             end

#         end
#     end
#     gdict = Dict{String, Genotype}(genos)
#     [NSGAiiRecord(geno, odict[key]) for geno in values(gdict)]
# end
