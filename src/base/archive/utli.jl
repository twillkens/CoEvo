export getjl, lineage

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

