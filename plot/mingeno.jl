using Distributed
@everywhere using Pkg
@everywhere Pkg.activate(".")
@everywhere using JLD2
@everywhere using CoEvo

@everywhere function fillmingeno!(eco::String, trial::Int, writefreq::Int = 1000)
    ecopath = joinpath(ENV["COEVO_DATA_DIR"], eco)
    lockpath = joinpath(ecopath, "lock")
    archiver = FSMIndivArchiver()
    jld2path = joinpath(ecopath, "$trial.jld2")
    jld2file = jldopen(jld2path, "a+")
    for genkey in keys(jld2file["arxiv"])
        if parse(Int, genkey) % writefreq == 0
            lock = mkpidlock(lockpath)
            println("$trial-$genkey got lock")
            @time close(jld2file)
            close(lock)
            jld2file = jldopen(jld2path, "a+")
        end
        gengroup = jld2file["arxiv"][genkey]
        allspgroup = gengroup["species"]
        for spid in keys(allspgroup)
            spgroup = allspgroup[spid]
            childrengroup = spgroup["children"]
            for iid in keys(childrengroup)
                childgroup = childrengroup[iid]
                if "mingeno" in keys(childgroup)
                    continue
                end
                geno = archiver(childgroup["geno"])
                mingeno = minimize(geno)
                make_group!(childgroup, "mingeno")
                mingenogroup = childgroup["mingeno"]
                archiver(mingenogroup, mingeno)
            end
        end
    end
    close(jld2file)
end

function fillmingeno!(eco::String, trials::UnitRange{Int}, writefreq = 1000)
    futures = [
        @spawnat :any fillmingeno!(eco, trial, writefreq) 
        for trial in trials]
    [fetch(future) for future in futures]
end
