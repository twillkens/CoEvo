using Plots
using Plots: plot
using StatsBase
using Distributions
using DataFrames
using Measures
using Serialization
Plots.default(fontfamily = ("Times Roman"))# titlefont = ("Times Roman"), legendfont = ("Times Roman"))
gr()

function label(args...)
    lstrip(join(args, '-'), '-')
end

function spplot(eco::String, metric::String, sp1::String, sp2::String, tag::String = "ko-40")
    X1, low1, hi1 = getline(eco = eco, tag = tag, geno = "min", metric = metric, sp = sp1)
    X2, low2, hi2 = getline(eco = eco, tag = tag, geno = "modes", metric = metric, sp = sp1)
    X3, low3, hi3 = getline(eco = eco, tag = tag, geno = "min", metric = metric, sp = sp2)
    X4, low4, hi4 = getline(eco = eco, tag = tag, geno = "modes", metric = metric, sp = sp2)
    p = plot(1:1000, X1, ribbon = (low1, hi1), fillalpha = 0.25, color = :blue)
    p = plot(p, 1:1000, X2, ribbon = (low2, hi2), fillalpha = 0.25, color = :red)
    p = plot(p, 1:1000, X3, ribbon = (low3, hi3), fillalpha = 0.25, color = :green)
    p = plot(p, 1:1000, X4, ribbon = (low4, hi4), fillalpha = 0.25, color = :orange)
    tickdict = Dict(0 => "0", 500 => "25,000", 1000 => "50,000")
    ydict = Dict(
        "complexity" => "Complexity",
        "novelty" => "Novelty",
        "ecology" => "Ecology",
        "levdist" => "Levenshtein Distance",
        "change" => "Change",
        "fitness" => "Fitness",
        "eplen" => "Episode Length",
    )
    ylimdict = Dict(
        "complexity" => (0, 100),
        "novelty" => (0, 5),
        "ecology" => (0, 5),
        "levdist" => (0, 25),
        "change" => (0, 5),
        "fitness" => (0, 1),
        "eplen" => (0, 25),
    )
    plot(
        p,
        ylim = ylimdict[metric],
        xformatter = (x) -> x in keys(tickdict) ? tickdict[x] : "",
        xlabel = "Generations",
        ylabel = ydict[metric],
    )
end

function threeplots(metric::String, tag::String)
    X1, low1, hi1 = getline(eco = "ctrl", tag = "$tag-40", geno = "min", metric = metric,)
    X2, low2, hi2 = getline(eco = "matchmix", tag = "$tag-40", geno = "min", metric = metric,)
    X3, low3, hi3 = getline(eco = "mismatchmix", tag = "$tag-20", geno = "min", metric = metric,)
    X4, low4, hi4 = getline(eco = "matchmix", tag = "$tag-40", geno = "modes", metric = metric)
    X5, low5, hi5 = getline(eco = "mismatchmix", tag = "$tag-20", geno = "modes", metric = metric)
    p = plot(1:1000,    X1, ribbon = (low1, hi1), fillalpha = 0.25, color = :blue, label = "Control")
    p = plot(p, 1:1000, X2, ribbon = (low2, hi2), fillalpha = 0.25, color = :red, label = "MatchMix")
    p = plot(p, 1:1000, X3, ribbon = (low3, hi3), fillalpha = 0.25, color = :green, label = "MismatchMix")
    p = plot(p, 1:1000, X4, ribbon = (low4, hi4), fillalpha = 0.25, color = :orange, label = "MatchMix-KO")
    p = plot(p, 1:1000, X5, ribbon = (low5, hi5), fillalpha = 0.25, color = :violet, label = "MismatchMix-KO")
    tickdict = Dict(0 => "0", 500 => "25,000", 1000 => "50,000")
    ydict = Dict(
        "complexity" => "Complexity",
        "novelty" => "Novelty",
        "ecology" => "Ecology",
        "levdist" => "Levenshtein Distance",
        "change" => "Change",
        "fitness" => "Fitness",
        "eplen" => "Episode Length",
    )
    ylimdict = Dict(
        "complexity" => (0, 100),
        "novelty" => (0, 6),
        "ecology" => (0, 6),
        "levdist" => (0, 25),
        "change" => (0, 6),
        "fitness" => (0, 25),
        "eplen" => (0, 25),
    )
    FSIZE = 20
    plot(
        p,
        ylim = ylimdict[metric],
        xformatter = (x) -> x in keys(tickdict) ? tickdict[x] : "",
        xlabel = "Generations",
        ylabel = ydict[metric],
        title = "Three Species: $(ydict[metric])",
        size = (1025, 650), 
        dpi = 300,
        left_margin = 8mm,
        right_margin = 5mm,
        top_margin = 5mm,
        bottom_margin = 10mm,
        ylabelfontsize = FSIZE,
        xlabelfontsize = FSIZE,
        tickfontsize = FSIZE - 4,
        legendfontsize=FSIZE - 8,
        #top_margin=0mm, 
        #bottom_margin=0mm, 
        #left_margin=0mm, 
        #right_margin=0mm, 
        titlefontsize=FSIZE+1,
    )
end

function twoplots(metric::String)
    X1, low1, hi1 = getline(eco = "ctrl", tag = "ko-40", geno = "min", metric = metric,)
    X2, low2, hi2 = getline(eco = "comp", tag = "ko-40", geno = "min", metric = metric,)
    X3, low3, hi3 = getline(eco = "coop", tag = "ko-40", geno = "min", metric = metric,)
    X4, low4, hi4 = getline(eco = "comp", tag = "ko-40", geno = "modes", metric = metric)
    X5, low5, hi5 = getline(eco = "coop", tag = "ko-40", geno = "modes", metric = metric)
    p = plot(1:1000,    X1, ribbon = (low1, hi1), fillalpha = 0.25, color = :blue, label = "Control")
    p = plot(p, 1:1000, X2, ribbon = (low2, hi2), fillalpha = 0.25, color = :red, label = "Comp")
    p = plot(p, 1:1000, X3, ribbon = (low3, hi3), fillalpha = 0.25, color = :green, label = "Coop")
    p = plot(p, 1:1000, X4, ribbon = (low4, hi4), fillalpha = 0.25, color = :orange, label = "Comp-KO")
    p = plot(p, 1:1000, X5, ribbon = (low5, hi5), fillalpha = 0.25, color = :violet, label = "Coop-KO")
    tickdict = Dict(0 => "0", 500 => "25,000", 1000 => "50,000")
    ydict = Dict(
        "complexity" => "Complexity",
        "novelty" => "Novelty",
        "ecology" => "Ecology",
        "levdist" => "Levenshtein Distance",
        "change" => "Change",
        "fitness" => "Fitness",
        "eplen" => "Episode Length",
    )
    ylimdict = Dict(
        "complexity" => (0, 100),
        "novelty" => (0, 6),
        "ecology" => (0, 6),
        "levdist" => (0, 25),
        "change" => (0, 6),
        "fitness" => (0, 25),
        "eplen" => (0, 25),
    )
    FSIZE = 20
    plot(
        p,
        ylim = ylimdict[metric],
        xformatter = (x) -> x in keys(tickdict) ? tickdict[x] : "",
        xlabel = "Generations",
        ylabel = ydict[metric],
        title = "Two Species: $(ydict[metric])",
        size = (1025, 650), 
        dpi = 300,
        left_margin = 8mm,
        right_margin = 5mm,
        top_margin = 5mm,
        bottom_margin = 10mm,
        ylabelfontsize = FSIZE,
        xlabelfontsize = FSIZE,
        tickfontsize = FSIZE - 4,
        legendfontsize=FSIZE - 8,
        #top_margin=0mm, 
        #bottom_margin=0mm, 
        #left_margin=0mm, 
        #right_margin=0mm, 
        titlefontsize=FSIZE+1,
    )
end

function levdist(eco::String, tag1::String, tag2::String)
    X1, low1, hi1 = getline(eco = eco, tag = tag1, geno = "", metric = "levdist")
    X2, low2, hi2 = getline(eco = eco, tag = tag2, geno = "", metric = "levdist")
    p = plot(1:1000, X1, ribbon = (low1, hi1), fillalpha = 0.25, color = :red)
    p = plot(p, 1:1000, X2, ribbon = (low2, hi2), fillalpha = 0.25, color = :blue)
end



function getline(;
    eco::String = "comp", 
    tag::String = "age-40", 
    geno::String = "min",
    metric::String = "complexity", 
    sp::String = "",
    trial::Int = -1,
    dir::String = "modesdata",
    mid::String = "mean",
    upper::String = "upper-conf",
    lower::String = "lower-conf",
)
    df = deserialize("$dir/$eco-$tag.jls")
    if trial == - 1
        X = df[!, label(sp, geno, metric, mid)]
        lower = df[!, label(sp, geno, metric, lower)]
        upper = df[!, label(sp, geno, metric, upper)]

        rlow = [x - l for (x, l) in zip(X, lower)]
        rhi = [u - x for (u, x) in zip(upper, X)] 
        return X, rlow, rhi
    else
        df[!, label(sp, geno, metric, trial)]
    end
end

function quickplot(;
    eco::String = "comp", 
    tag::String = "age-40", 
    geno::String = "min",
    metric::String = "complexity", 
    sp::String = "",
    trial::Int = -1,
    dir::String = "modesdata",
    mid::String = "mean",
    upper::String = "upper-conf",
    lower::String = "lower-conf",
    fillalpha::Float64 = 0.25,
)
    df = deserialize("$dir/$eco-$tag.jls")
    if trial == - 1
        X = df[!, label(sp, geno, metric, mid)]
        lower = df[!, label(sp, geno, metric, lower)]
        upper = df[!, label(sp, geno, metric, upper)]

        rlow = [x - l for (x, l) in zip(X, lower)]
        rhi = [u - x for (u, x) in zip(upper, X)] 

        return plot(X,
            ribbon = (rlow, rhi), 
            fillalpha = fillalpha
        )
    else
        X = df[!, label(sp, geno, metric, trial)]
        return plot(X)
    end
end

struct LineSpec
    title::String
    label::String
    color::String
    sp::String
    ylim::Tuple{Float64, Float64}
end

function LineSpec(title::String, label::String, color::String, col::String)
    LineSpec(title, label, color, col, (0, 300))
end

FSIZE = 20


function plotspec(df::DataFrame, spec::LineSpec,
                  line_alpha::Float64, ribbon_alpha::Float64,
                  dolegend::Bool, p=nothing; kwargs...)
    label = dolegend ? spec.label : ""
    lows = df[!, "$(spec.sp)-lower"]
    meds = df[!, "$(spec.sp)-med"]
    ups  = df[!, "$(spec.sp)-upper"]

    graph_lows = Vector{Float64}()
    graph_meds = Vector{Float64}()
    graph_ups = Vector{Float64}()
    for (low, med, up) in zip(lows, meds, ups)
        push!(graph_lows, med - low)
        push!(graph_meds, med)
        push!(graph_ups, up - med)
    end
    if p === nothing
        plot(1:length(graph_meds), graph_meds, ribbon=(graph_lows, graph_ups),
              ylim=spec.ylim, xticks=([0, 12500, 25000]), label=label,
              ylabelfontsize=FSIZE,
              xlabelfontsize=FSIZE,
              tickfontsize=FSIZE - 4,
                 legendfontsize=FSIZE - 8,
                top_margin=0mm, 
                bottom_margin=0mm, 
                left_margin=0mm, 
                right_margin=0mm, 
              title = spec.title,
              titlefontsize=FSIZE+1,
              xformatter=:plain, color=spec.color,
              linealpha=line_alpha, fillalpha=ribbon_alpha, grid=true; kwargs...)
    else
        plot(p, 1:length(graph_meds), graph_meds, ribbon=(graph_lows, graph_ups),
              ylabelfontsize=FSIZE,
              xlabelfontsize=FSIZE,
              tickfontsize=FSIZE - 4,
                 legendfontsize=FSIZE - 8,
                top_margin=0mm, 
                bottom_margin=0mm, 
                left_margin=0mm, 
                right_margin=0mm, 
              title=spec.title, 
              titlefontsize=FSIZE + 1,
              ylim=spec.ylim, xticks=([0, 12500, 25000]), label=label,
              xformatter=:plain, color=spec.color,
              linealpha=line_alpha, fillalpha=ribbon_alpha, grid=true; kwargs...)
    end

end


function doplot(df::DataFrame, specs::Vector{LineSpec}; kwargs...)
    p = plotspec(df, specs[1], 0.0, 0.15, false, nothing; kwargs...)
    for spec in specs[2:end]
        p = plotspec(df, spec, 0.0, 0.15, false, p; kwargs...)
    end
    for spec in specs[1:end]
        p = plotspec(df, spec, 0.99, 0.0, true, p; kwargs...)
    end
    #annotate!(12500, specs[1].ylim[2] - 30, text(specs[1].title))
    p
end

function plot_eco_geno(
    df::DataFrame, linespecs::Vector{LineSpec},
    xticks::Vector{Int} = [0, 25000, 50000],
    yticks::Vector{Int} = [0, 50, 100, 150, 200, 250, 300]
)
    legend = :topleft
    xticks = (xticks)
    xlabel = "Generation"
    yticks = (yticks)
    ylabel = "Complexity"
    xformatter = :plain
    yformatter = :plain
    doplot(
        df, linespecs;
        legend = legend,
        xticks = xticks, yticks = yticks,
        xlabel = xlabel, ylabel = ylabel,
        xformatter = xformatter, yformatter = yformatter
    )
end

function plot_eco_mingeno(
    df::DataFrame, linespecs::Vector{LineSpec},
    xticks::Vector{Int} = [0, 25000, 50000],
    yticks::Vector{Int} = [0, 50, 100, 150, 200, 250, 300]
)

    legend = false
    xticks = (xticks)
    xlabel = "Generation"
    yticks = (yticks)
    ylabel = ""
    xformatter = :plain
    yformatter = (y) -> ""
    doplot(
        df, linespecs;
        legend = legend,
        xticks = xticks, yticks = yticks,
        xlabel = xlabel, ylabel = ylabel,
        xformatter = xformatter, yformatter = yformatter
    )
end


function plotmodes(df::DataFrame, eco::String, metric::String, color::String, ylim::Tuple{Int, Int})
    savefig(
        plot(df[!, "modes-$metric-mean"], 
            title = "$eco-$metric", 
            ylim=ylim,
            color = color
            ),  
        "img/modes/$eco/$metric.png"
    )
end


function plot_eco(eco::String, color::String = "black")
    df = deserialize("modesdata/$eco.jls")
    rm("img/modes/$eco", recursive=true, force=true)
    mkdir("img/modes/$eco")
    plotmodes(df, eco, "change", color, (0, 5))
    plotmodes(df, eco, "novelty", color, (0, 5))
    plotmodes(df, eco, "complexity", color, (0, 20))
    plotmodes(df, eco, "ecology", color, (0, 5))
end


function plot_control()
    df = deserialize("modesdata/ctrl.jls")
    geno1 = LineSpec("Control-Complexity", "ctrl1", "red", "ctrl1-min-complexity")
    geno2 = LineSpec("Control-Complexity", "ctrl2", "blue", "ctrl2-min-complexity")
    geno = plot_eco_geno(df, [geno1, geno2])
    min1 = LineSpec("Control-Min ", "ctrl1", "red", "ctrl1-min")
    min2 = LineSpec("Control-Min ", "ctrl2", "blue", "ctrl2-min")
    mingeno = plot_eco_mingeno(df, [min1, min2])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/ctrl.png")
end

function plot_comp()
    df = deserialize("counts/comp.jls")
    geno1 = LineSpec("Comp-Geno", "host", "blue", "host-geno")
    geno2 = LineSpec("Comp-Geno", "parasite", "red", "parasite-geno")
    geno = plot_eco_geno(df, [geno1, geno2])
    min1 = LineSpec("Comp-Min ", "host", "blue", "host-min")
    min2 = LineSpec("Comp-Min ", "parasite", "red", "parasite-min")
    mingeno = plot_eco_mingeno(df, [min1, min2])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/comp.png")
end

function plot_coop()
    df = deserialize("counts/coop.jls")
    geno1 = LineSpec("Coop-Geno", "host", "blue", "host-geno")
    geno2 = LineSpec("Coop-Geno", "symbiote", "green", "symbiote-geno")
    geno = plot_eco_geno(df, [geno1, geno2])
    min1 = LineSpec("Coop-Min ", "host", "blue", "host-min")
    min2 = LineSpec("Coop-Min ", "symbiote", "green", "symbiote-min")
    mingeno = plot_eco_mingeno(df, [min1, min2])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/coop.png")
end

function plot_matchcoop()
    df = deserialize("counts/MatchCoop-MatchComp.jls")
    geno1 = LineSpec("MatchCoop-Geno", "host", "blue", "host-geno")
    geno2 = LineSpec("MatchCoop-Geno", "symbiote", "green", "symbiote-geno")
    geno3 = LineSpec("MatchCoop-Geno", "parasite", "red", "parasite-geno")
    geno = plot_eco_geno(df, [geno1, geno2, geno3])
    min1 = LineSpec("MatchCoop-Min", "host", "blue", "host-min")
    min2 = LineSpec("MatchCoop-Min", "symbiote", "green", "symbiote-min")
    min3 = LineSpec("MatchCoop-Min", "parasite", "red", "parasite-min")
    mingeno = plot_eco_mingeno(df, [min1, min2, min3])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/matchcoop.png")
end

function plot_mismatchcoop()
    df = deserialize("counts/MismatchCoop-MatchComp.jls")
    geno1 = LineSpec("MismatchCoop-Geno", "host", "blue", "host-geno")
    geno2 = LineSpec("MismatchCoop-Geno", "symbiote", "green", "symbiote-geno")
    geno3 = LineSpec("MismatchCoop-Geno", "parasite", "red", "parasite-geno")
    geno = plot_eco_geno(df, [geno1, geno2, geno3])
    min1 = LineSpec("MismatchCoop-Min", "host", "blue", "host-min")
    min2 = LineSpec("MismatchCoop-Min", "symbiote", "green", "symbiote-min")
    min3 = LineSpec("MismatchCoop-Min", "parasite", "red", "parasite-min")
    mingeno = plot_eco_mingeno(df, [min1, min2, min3])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/mismatchcoop.png")
end

function plot_mismatchcycle()
    df = deserialize("counts/mismatchcycle-counts.jls")
    geno1 = LineSpec("MismatchCycle-Geno", "X", "blue", "x-geno")
    geno2 = LineSpec("MismatchCycle-Geno", "Y", "green", "y-geno")
    geno3 = LineSpec("MismatchCycle-Geno", "Z", "red", "z-geno")
    geno = plot_eco_geno(df, [geno1, geno2, geno3])
    min1 = LineSpec("MismatchCoop-Min", "X", "blue", "x-min")
    min2 = LineSpec("MismatchCoop-Min", "Y", "green", "y-min")
    min3 = LineSpec("MismatchCoop-Min", "Z", "red", "z-min")
    mingeno = plot_eco_mingeno(df, [min1, min2, min3])
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/mismatchcycle.png")
end

function plot_4MatchMix()
    df = deserialize("counts/4MatchMix-counts.jls")
    geno = plot_eco_geno(
        df, 
        [
            LineSpec("4MatchMix-Geno", "A", "blue", "A-geno"),
            LineSpec("4MatchMix-Geno", "B", "green", "B-geno"),
            LineSpec("4MatchMix-Geno", "C", "red", "C-geno"),
            LineSpec("4MatchMix-Geno", "D", "orange", "D-geno"),
        ], 
        [0, 250, 500]
    )
    mingeno = plot_eco_mingeno(
        df,
        [
            LineSpec("4MatchMix-Min", "A", "blue", "A-min"),
            LineSpec("4MatchMix-Min", "B", "green", "B-min"),
            LineSpec("4MatchMix-Min", "C", "red", "C-min"),
            LineSpec("4MatchMix-Min", "D", "orange", "D-min"),
        ],
        [0, 250, 500]
    )
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/4MatchMix.png")
end

function plot_4MatchMismatchMix()
    df = deserialize("counts/4MatchMismatchMix-counts.jls")
    geno = plot_eco_geno(
        df, 
        [
            LineSpec("4MatchMismatchMix-Geno", "A", "blue", "A-geno"),
            LineSpec("4MatchMismatchMix-Geno", "B", "green", "B-geno"),
            LineSpec("4MatchMismatchMix-Geno", "C", "red", "C-geno"),
            LineSpec("4MatchMismatchMix-Geno", "D", "orange", "D-geno"),
        ], 
        [0, 250, 500]
    )
    mingeno = plot_eco_mingeno(
        df,
        [
            LineSpec("4MatchMismatchMix-Min", "A", "blue", "A-min"),
            LineSpec("4MatchMismatchMix-Min", "B", "green", "B-min"),
            LineSpec("4MatchMismatchMix-Min", "C", "red", "C-min"),
            LineSpec("4MatchMismatchMix-Min", "D", "orange", "D-min"),
        ],
        [0, 250, 500]
    )
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/4MatchMismatchMix.png")
end


function plot_4MismatchMatchMix()
    eco = "4MismatchMatchMix"
    df = deserialize("counts/$eco-counts.jls")
    geno = plot_eco_geno(
        df, 
        [
            LineSpec("$eco-Geno", "A", "blue", "A-geno"),
            LineSpec("$eco-Geno", "B", "green", "B-geno"),
            LineSpec("$eco-Geno", "C", "red", "C-geno"),
            LineSpec("$eco-Geno", "D", "orange", "D-geno"),
        ], 
        [0, 250, 500]
    )
    mingeno = plot_eco_mingeno(
        df,
        [
            LineSpec("$eco-Min", "A", "blue", "A-min"),
            LineSpec("$eco-Min", "B", "green", "B-min"),
            LineSpec("$eco-Min", "C", "red", "C-min"),
            LineSpec("$eco-Min", "D", "orange", "D-min"),
        ],
        [0, 250, 500]
    )
    plot(geno, mingeno,
         size=(1025, 325), dpi=300,
         left_margin=8mm,right_margin=5mm, top_margin=5mm, bottom_margin=10mm)
    savefig("img/$eco.png")
end

function doall()
    plot_control()
    plot_coop()
    plot_comp()
    plot_mix()
    plot_cycle()
    plot_compcycle()
    plot_fitness()
end


using StatsPlots

function raincloud(data)
    p = violin(data,
               side=:left,
               show_mean = true,
               show_median = true,
               quantiles = [0.25, 0.75],
               leg=false)

    for col in 1:size(data)[2]
        display(scatter!(col .+ 0.1 .+ 0.3 .* rand(size(data)[1]),
                data[:, col], color=col))
    end

end

# raincloud(rand(100, 5))
