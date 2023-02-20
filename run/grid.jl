using Distributed
@everywhere include("fluxclass.jl")


function pgrid(;eco1::String = "comp", spid1::Symbol = :host, iid1::Int = 1,
              eco2::String = "Grow", spid2::Symbol = :control1, iid2::Int = 1,
              nsample::Int = 1000, gen::Int = 999, min::Bool = true, rev_spec::Bool = false,
              fixtrial::Int = -1, trialrange::UnitRange = 1:50)
    futures = []
    for i in trialrange
        ckey1 = fixtrial == -1 ? "$(eco1)-$(i)" : "$(eco1)-$(fixtrial)" 
        dargs = DatasetArgs(
            jl1 = JLArgs(ckey = ckey1, spid = spid1, iid = iid1),
            jl2 = JLArgs(ckey = "$(eco2)-$(i)", spid = spid2, iid = iid2),
            nsample = nsample, gen = gen, min = min, rev_spec = rev_spec
        )
        f = @spawnat :any makedataset(dargs)
        push!(futures, f)
    end
    [fetch(f) for f in futures]
end
#         push!(sums, sum(d))
#         println(sum(sums), mean(sums), std(sums))
#     end
#     sum(sums), mean(sums), std(sums)