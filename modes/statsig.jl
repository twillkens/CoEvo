using Serialization
using CSV
using Pingouin
using HypothesisTests
using GLM, Plots, TypedTables, CSV

function change2()
    ctrl = deserialize("modesdata/ctrl-ko-40.jls")
    comp = deserialize("modesdata/comp-ko-40.jls")
    coop = deserialize("modesdata/coop-ko-40.jls")
    change = DataFrame(Dict(
        "ctrl-hop" => ctrl[!, "min-change-mean"],
        "comp-hop" => comp[!, "min-change-mean"],
        "comp-ko" => comp[!, "modes-change-mean"],
        "coop-hop" => coop[!, "min-change-mean"],
        "coop-ko" => coop[!, "modes-change-mean"],
    ))
    KruskalWallisTest(collect(eachcol(change))...)
end

struct RegressionResult
    dataset::String
    metric::String
    ols::StatsModels.TableRegressionModel
    plot::Plots.Plot
    intercept::Float64
    slope::Float64
end

function do_regression(dataset::String, metric::String, start::Int = 500, stop::Int = 1_000)
    df = deserialize("modesdata/$(dataset).jls")

    Y = df[!, metric][start:stop]
    X = collect(start:stop)
    t = Table(X = X, Y = Y)
    ols = lm(@formula(Y ~ X), t)
    p = scatter(X, Y, ylim = (0,5), xlim=(start, stop))
    ols, plot(p, X, predict(ols), color = :red, linewidth = 3, ylim=(0, 5), title = "$(dataset)-$(metric)")
end

function do_regression(
    datasets::Vector{String} = [        
        "comp-new-40", 
        "coop-new-40", 
        "ctrl-new-40", 
        "3comp-new-40", 
        "mismatchmix-new-40", 
        "3ctrl-new-40"
    ],
    metrics::Vector{String} = [
        "eco-hopcroft-change-mean", 
        "eco-age-change-mean", 
        "eco-hopcroft-novelty-mean", 
        "eco-age-novelty-mean",
        "eco-hopcroft-complexity-mean", 
        "eco-age-complexity-mean",
        "eco-hopcroft-ecology-mean", 
        "eco-age-ecology-mean",
    ]
)
    results = RegressionResult[]
    for dataset in datasets
        for metric in metrics
            ols, plot = do_regression(dataset, metric)
            push!(results, RegressionResult(
                dataset, metric, ols, plot, coef(ols)[1], coef(ols)[2])
            )
        end
    end
    results
end

function getgroupdata(
    dataset::String = "ctrl-new-40", 
    metric::String = "eco-hopcroft-change", 
    t::Int = 1_000,
    trials::UnitRange{Int} = 1:40
)
    df = deserialize("modesdata/$(dataset).jls")
    metricdata = Float64[]
    for trial in trials
        name = "$(metric)-$(trial)"
        val = df[!, name][t]
        push!(metricdata, val)
    end
    metricdata
end

function do_wilcoxon(;
    dset1::String = "ctrl-new-40", 
    metric1::String = "eco-hopcroft-change", 
    dset2::String = "comp-new-40", 
    metric2::String = "eco-hopcroft-change", 
    t::Int = 1_000,
    trials::UnitRange{Int} = 1:40
)
    data1 = getgroupdata(dset1, metric1, t, trials)
    data2 = getgroupdata(dset2, metric2, t, trials)
    SignedRankTest(data1, data2), Pingouin.compute_effsize(data1, data2, eftype = "glass")
end


function do_kruskall_wallace(;
    metric::String = "change",
    entries::Dict{String, Vector{String}} = Dict(
        "comp-new-40" => ["eco-hopcroft-$(metric)", "eco-age-$(metric)",], 
        "coop-new-40" => ["eco-hopcroft-$(metric)", "eco-age-$(metric)",], 
        "ctrl-new-40" => ["eco-hopcroft-$(metric)", "eco-age-$(metric)",],
    ),
    trials::UnitRange{Int} = 1:40,
    t::Int = 1_000
)
    alldata = []
    for (dataset, metrics) in entries
        df = deserialize("modesdata/$(dataset).jls")
        for metric in metrics
            metricdata = Float64[]
            for trial in trials
                name = "$(metric)-$(trial)"
                val = df[!, name][t]
                println(val)
                push!(metricdata, val)
            end
            push!(alldata, metricdata)
        end
    end
    KruskalWallisTest(alldata...)
end