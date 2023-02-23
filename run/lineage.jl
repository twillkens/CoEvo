function makeFSMIndiv(spid::Symbol, iid::UInt32, igroup::JLD2.Group)
    ones = Set(string(o) for o in igroup["ones"])
    zeros = Set(string(z) for z in igroup["zeros"])
    pids = Set(p for p in igroup["pids"])
    start = igroup["start"]
    links = Dict((string(s), w) => string(t) for (s, w, t) in igroup["links"])
    geno = FSMGeno(IndivKey(spid, iid), start, ones, zeros, links)
    FSMIndiv(geno.ikey, geno, pids)
end

function makeFSMIndiv(spid::Symbol, iid::String, igroup::JLD2.Group)
    makeFSMIndiv(spid, parse(UInt32, iid), igroup)
end

function makeFSMIndiv(spid::String, iid::String, igroup::JLD2.Group)
    makeFSMIndiv(Symbol(spid), parse(UInt32, iid), igroup)
end

function getjl(ckey::String = "comp-1")
    jldopen("$(ENV["FSM_DATA_DIR"])/$(split(ckey, "-")[1])/$(ckey).jld2")
end

function lineage(
    jl::JLD2.JLDFile, gen::Int, spid::Symbol, pid::String, indivs::Vector{FSMIndiv}
)
    if gen == 1
        close(jl)
        return reverse(indivs)
    end
    igroup = jl["$(gen)"]["species"]["$(spid)"]["$(pid)"]
    indiv = makeFSMIndiv(spid, pid, igroup)
    push!(indivs, indiv)
    pid = first(indiv.pids)
    lineage(jl, gen - 1, spid, string(pid), indivs)
end


function lineage(jl::JLD2.JLDFile, gen::Int, spid::Symbol, aliasid::Int)
    iid = collect(keys(jl["$(gen)"]["species"]["$(spid)"]))[aliasid + 1]
    igroup = jl["$(gen)"]["species"]["$(spid)"]["$(iid)"]
    indiv = makeFSMIndiv(spid, iid, igroup)
    pid = first(indiv.pids)
    lineage(jl, gen - 1, spid, string(pid), [indiv])
end

function lineage(jl::String, gen::Int, spid::Symbol, aliasid::Int)
    lineage(getjl(jl), gen, spid, aliasid)
end


