using Distributed
@everywhere include("fluxclass.jl")


function pgrid(;eco1::String = "comp", spid1::Symbol = :host, iid1::Int = 1,
              eco2::String = "Grow", spid2::Symbol = :control1, iid2::Int = 1,
              nsample::Int = 1000, gen::Int = 999, min::Bool = true, rev_spec::Bool = false,
              fixtrial::Int = -1, trange::UnitRange = 1:20, sumdist = true)
    futures = []
    for i in trange
        ckey1 = fixtrial == -1 ? "$(eco1)-$(i)" : "$(eco1)-$(fixtrial)" 
        dargs = DatasetArgs(
            jl1 = JLArgs(ckey = ckey1, spid = spid1, iid = iid1),
            jl2 = JLArgs(ckey = "$(eco2)-$(i)", spid = spid2, iid = iid2),
            nsample = nsample, gen = gen, min = min,
            rev_spec = rev_spec, sumdist = sumdist
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
function igrid(;eco1::String = "comp", spid1::Symbol = :host, iidr1::UnitRange = 1:1,
              eco2::String = "Grow", spid2::Symbol = :control1, iidr2::UnitRange = 1:50,
              nsample::Int = 1000, gen::Int = 999, min::Bool = true, rev_spec::Bool = false,
              trial::Int = 1, sumdist = true)
    futures = []
    for iid1 in iidr1
        for iid2 in iidr2
            dargs = DatasetArgs(
                jl1 = JLArgs(ckey = "$(eco1)-$(trial)", spid = spid1, iid = iid1),
                jl2 = JLArgs(ckey = "$(eco2)-$(trial)", spid = spid2, iid = iid2),
                nsample = nsample, gen = gen, min = min,
                rev_spec = rev_spec, sumdist = sumdist
            )
            f = @spawnat :any makedataset(dargs)
            push!(futures, f)
        end
    end
    [fetch(f) for f in futures]
end