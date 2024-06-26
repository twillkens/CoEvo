using CSV
using DataFrames
using Plots
using Statistics
using Bootstrap
using Bootstrap: bootstrap, BasicSampling, BasicConfInt, confint as bootstrap_confint
using StatsBase: nquantile, skewness, kurtosis, mode, mean, var, std
using Glob
using Plots.PlotMeasures

gr()
# Define a struct to hold file details
struct FileDetail
    filepath::String
    label::String
    color::Symbol
end

const DEFAULT_BOOTSTRAPPED_CONFIDENCE_INTERVALS = Dict(
        "lower_confidence" => 0,
        "upper_confidence" => 0,
)
const N_BOOTSTRAP_SAMPLES = 1000

const DEFAULT_CONFIDENCE = 0.95

const N_TRIALS = 20
const N_GENERATIONS = 10000

function get_bootstrapped_confidence_intervals(
    values::Vector{Float64}, confidence_level::Float64 = 0.95
)
    if length(values) == 0
        return Dict("lower_confidence" => 0, "upper_confidence" => 0)
    end
    bootstrap_result = bootstrap(mean, values, BasicSampling(1000))
    _, lower_confidence, upper_confidence = first(bootstrap_confint(
        bootstrap_result, BasicConfInt(confidence_level)
    ))
    confidence_intervals = Dict(
        "lower_confidence" => lower_confidence,
        "upper_confidence" => upper_confidence,
    )
    return confidence_intervals
end


struct PlotDetail
    algorithm::String
    label::String
    color::Symbol
end

function plot_scores(
    data_filepath::String,
    details::Vector{PlotDetail}; 
    title::String="Density Classification Task: Accuracy",
    legend::Symbol=:bottomright,
    ylabel::String="Accuracy",
    save_path::String="dct",
    ycolumn::String="utility",
    ylims::Tuple{Float64, Float64}=(-1.0, -1.0),
    xlims::Tuple{Float64, Float64}=(-1.0, -1.0)
)
    p = plot(legend=legend, xlabel="Generation", ylabel=ylabel, title=title)
    df = CSV.read(data_filepath, DataFrame)
    for detail in details
        # Read the CSV file
        data = filter(row -> row.algorithm == detail.algorithm, df)
         if ylims ==  (-1.0, -1.0)
            ylims = nothing
         end
         if xlims ==  (-1.0, -1.0)
            xlims = nothing
         end

        # Process the dataset
        grouped = groupby(data, :generation)
        
        # Initialize vectors for generations, means, and confidence intervals
        generations = Int[]
        means = Float64[]
        lower_cis = Float64[]
        upper_cis = Float64[]

        for group in grouped
            gen = group[1, :generation]  # Extracting the generation value
            group_scores = group[:, Symbol(ycolumn)]  # Extracting scores for this generation

            push!(generations, gen)
            push!(means, mean(group_scores))

            ci = get_bootstrapped_confidence_intervals(group_scores, DEFAULT_CONFIDENCE)
            push!(lower_cis, ci["lower_confidence"])
            push!(upper_cis, ci["upper_confidence"])
        end

        # Plotting data from the current file
        plot!(
            p, generations, means, 
            ribbon = (means .- lower_cis, upper_cis .- means), 
            fillalpha = 0.35, 
            label = detail.label,
            color = detail.color, 
            size = (1600, 800), 
            leftmargin = 40mm, bottommargin = 15mm, rightmargin = 15mm, topmargin = 15mm,
            ylims = ylims, xlims = xlims,
            legendfont = font(25),
            titlefont = font(30),
            tickfont = font(20),
            guidefont = font(25),
        )
    end

    savefig(p, "$save_path.png")
    display(p)
end


function plot_coo_easy()
    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("cfs_std", "CFS/STD", :purple),
            PlotDetail("doc_std", "DOC/STD", :green),
            PlotDetail("roulette", "ROULETTE", :blue),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: Genetic Algorithms", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_ga_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("cfs_std", "CFS/STD", :purple),
            PlotDetail("doc_std", "DOC/STD", :green),
            PlotDetail("roulette", "ROULETTE", :blue),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: Genetic Algorithms", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_ga",
        ylims=(0.0, 17.0),
        xlims=(0.0, 500.0)
    )


    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("p_phc_p_frs", "P-PHC-P-FRS", :orange),
            PlotDetail("p_phc_p_uhs", "P-PHC-P-UHS", :brown),
            PlotDetail("p_phc", "P-PHC", :grey),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: Population Pareto Hillclimbers", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_phc_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("p_phc_p_frs", "P-PHC-P-FRS", :orange),
            PlotDetail("p_phc_p_uhs", "P-PHC-P-UHS", :brown),
            PlotDetail("p_phc", "P-PHC", :grey),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: Population Pareto Hillclimbers", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_phc",
        ylims=(0.0, 17.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("doc_qmeu_fast", "DOC/Q-FAST", :magenta),
            PlotDetail("cfs_qmeu_fast", "CFS/Q-FAST", :navy),
            PlotDetail("doc_qmeu_slow", "DOC/Q-SLOW", :lime),
            PlotDetail("cfs_qmeu_slow", "CFS/Q-SLOW", :olive),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: QueMEU Variants", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_qmeu_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_easy_agg.csv",
        [
            PlotDetail("doc_qmeu_fast", "DOC/Q-FAST", :magenta),
            PlotDetail("cfs_qmeu_fast", "CFS/Q-FAST", :navy),
            PlotDetail("doc_qmeu_slow", "DOC/Q-SLOW", :lime),
            PlotDetail("cfs_qmeu_slow", "CFS/Q-SLOW", :olive),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Easy: QueMEU Variants", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_ez_qmeu",
        ylims=(0.0, 17.0),
        xlims=(0.0, 500.0)
    )
end

function plot_coo_hard()
    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("cfs_std", "CFS/STD", :purple),
            PlotDetail("doc_std", "DOC/STD", :green),
            PlotDetail("control", "CONTROL", :red),
            PlotDetail("roulette", "ROULETTE", :blue),
        ],
        legend=:topright, 
        title="COO-Hard: Genetic Algorithms", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_ga_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("p_phc", "P-PHC", :grey),
            PlotDetail("p_phc_p_frs", "P-PHC-P-FRS", :orange),
            PlotDetail("p_phc_p_uhs", "P-PHC-P-UHS", :brown),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Hard: Population Pareto Hillclimbers", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_phc_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("cfs_qmeu_fast", "CFS/Q-FAST", :navy),
            PlotDetail("doc_qmeu_fast", "DOC/Q-FAST", :magenta),
            PlotDetail("cfs_qmeu_slow", "CFS/Q-SLOW", :olive),
            PlotDetail("doc_qmeu_slow", "DOC/Q-SLOW", :lime),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Hard: QueMEU Variants", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_qmeu_scaled",
        ylims=(-1.0, -1.0),
        xlims=(0.0, 500.0)
    )
    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("cfs_std", "CFS/STD", :purple),
            PlotDetail("doc_std", "DOC/STD", :green),
            PlotDetail("control", "CONTROL", :red),
            PlotDetail("roulette", "ROULETTE", :blue),
        ],
        legend=:topright, 
        title="COO-Hard: Genetic Algorithms", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_ga",
        ylims=(0.0, 2.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("p_phc", "P-PHC", :grey),
            PlotDetail("p_phc_p_frs", "P-PHC-P-FRS", :orange),
            PlotDetail("p_phc_p_uhs", "P-PHC-P-UHS", :brown),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Hard: Population Pareto Hillclimbers", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_phc",
        ylims=(0.0, 2.0),
        xlims=(0.0, 500.0)
    )

    plot_scores(
        "coo_hard_agg.csv",
        [
            PlotDetail("cfs_qmeu_fast", "CFS/Q-FAST", :navy),
            PlotDetail("doc_qmeu_fast", "DOC/Q-FAST", :magenta),
            PlotDetail("cfs_qmeu_slow", "CFS/Q-SLOW", :olive),
            PlotDetail("doc_qmeu_slow", "DOC/Q-SLOW", :lime),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:topleft, 
        title="COO-Hard: QueMEU Variants", 
        ylabel="Minimum Dimension Value", 
        save_path="coo_hard_qmeu",
        ylims=(0.0, 2.0),
        xlims=(0.0, 500.0)
    )
end

function plot_fsm_128()
    plot_scores(
        "fsm_agg.csv",
        [
            PlotDetail("cfs_std", "CFS/STD", :purple),
            PlotDetail("doc_std", "DOC/STD", :green),
            PlotDetail("roulette", "ROULETTE", :blue),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:outertopright, 
        title="FSM-128 Binary Prediction Task: Genetic Algorithms", 
        ylabel="Expected Utility", 
        save_path="fsm_ga_scaled",
        ycolumn = "utility_128",
        ylims=(0.4, 0.66),
        #xlims=(0.0, 500.0)
    )

    plot_scores(
        "fsm_agg.csv",
        [
            PlotDetail("p_phc_ups", "P-PHC-P-UHS", :brown),
            PlotDetail("p_phc_frs", "P-PHC-P-FRS", :orange),
            PlotDetail("control", "CONTROL", :red),
            PlotDetail("p_phc", "P-PHC", :grey),
        ],
        legend=:outertopright, 
        title="FSM-128 Binary Prediction Task: Population Pareto Hillclimbers", 
        ylabel="Expected Utility", 
        save_path="fsm_phc_scaled",
        ycolumn = "utility_128",
        ylims=(0.4, 0.66),
        #xlims=(0.0, 500.0)
    )

    plot_scores(
        "fsm_agg.csv",
        [
            PlotDetail("cfs_qmeu_slow", "CFS/Q-SLOW", :olive),
            PlotDetail("doc_qmeu_slow", "DOC/Q-SLOW", :lime),
            PlotDetail("doc_qmeu_fast", "DOC/Q-FAST", :magenta),
            PlotDetail("cfs_qmeu_fast", "CFS/Q-FAST", :navy),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:outertopright, 
        title="FSM-128 Binary Prediction Task: Basic QueMEU Variants", 
        ylabel="Expected Utility", 
        save_path="fsm_qmeu_scaled",
        ycolumn = "utility_128",
        ylims=(0.4, 0.66),
        #xlims=(0.0, 500.0)
    )
    plot_scores(
        "fsm_agg.csv",
        [
            PlotDetail("cfs_qmeu_gamma", "CFS/Q-GAMMA", :indigo),
            PlotDetail("tourn_qmeu", "CFS/Q-BETA", :firebrick),
            PlotDetail("doc_qmeu_beta", "DOC/Q-BETA", :seagreen),
            PlotDetail("control", "CONTROL", :red),
        ],
        legend=:outertopright, 
        title="FSM-128 Binary Prediction Task: Advanced QueMEU Variants", 
        ylabel="Expected Utility", 
        save_path="fsm_qmeu_adv_scaled",
        ycolumn = "utility_128",
        ylims=(0.4, 0.66),
        #xlims=(0.0, 500.0)
    )
end

#plot_coo_easy()
#plot_coo_hard()
#plot_fsm_128()


function plot_scores_2(
    data_filepath::String,
    details::Vector{PlotDetail}; 
    title::String="Density Classification Task: Accuracy",
    legend::Symbol=:bottomright,
    ylabel::String="Accuracy",
    save_path::String="dct",
    ycolumns::Vector{String}=["utility_16", "utility_32", "utility_64", "utility_128"],
    labels::Vector{String}=["16 States", "32 States", "64 States", "128 States"],
    ylims::Tuple{Float64, Float64}=(-1.0, -1.0),
    xlims::Tuple{Float64, Float64}=(-1.0, -1.0)
)
    p = plot(legend=legend, xlabel="Generation", ylabel=ylabel, title=title)
    df = CSV.read(data_filepath, DataFrame)
    for (label, ycolumn) in zip(labels, ycolumns)
        for detail in details
            # Read the CSV file
            data = filter(row -> row.algorithm == detail.algorithm, df)
            if ylims ==  (-1.0, -1.0)
                ylims = nothing
            end
            if xlims ==  (-1.0, -1.0)
                xlims = nothing
            end

            # Process the dataset
            grouped = groupby(data, :generation)
            
            # Initialize vectors for generations, means, and confidence intervals
            generations = Int[]
            means = Float64[]
            lower_cis = Float64[]
            upper_cis = Float64[]

            for group in grouped
                gen = group[1, :generation]  # Extracting the generation value
                group_scores = group[:, Symbol(ycolumn)]  # Extracting scores for this generation

                push!(generations, gen)
                push!(means, mean(group_scores))

                ci = get_bootstrapped_confidence_intervals(group_scores, DEFAULT_CONFIDENCE)
                push!(lower_cis, ci["lower_confidence"])
                push!(upper_cis, ci["upper_confidence"])
            end

            # Plotting data from the current file
            plot!(
                p, generations, means, 
                ribbon = (means .- lower_cis, upper_cis .- means), 
                fillalpha = 0.35, 
                label = label,
                #color = detail.color, 
                size = (1600, 800), 
                leftmargin = 40mm, bottommargin = 15mm, rightmargin = 15mm, topmargin = 15mm,
                ylims = ylims, xlims = xlims,
                legendfont = font(25),
                titlefont = font(30),
                tickfont = font(20),
                guidefont = font(25),
            )
        end
    end

    savefig(p, "$save_path.png")
    display(p)
end

plot_scores_2(
    "fsm_agg.csv",
    [
        PlotDetail("cfs_qmeu_gamma", "CFS/Q-GAMMA", :indigo),
    ],
    legend=:outertopright, 
    title="FSM Binary Prediction Task: Q-GAMMA vs. Different Size Classes", 
    ylabel="Expected Utility", 
    save_path="fsm_qmeu_classes",
    ycolumns = ["utility_16","utility_32","utility_64","utility_128",],
    ylims=(0.4, 1.0),
    #xlims=(0.0, 500.0)
)

#COO_HARD = "logs/final_agg/coo/hard"
#
#coo_hard_files = [
#    FileDetail("$COO_HARD/doc-standard.csv", "Standard", :red),
#    FileDetail("$COO_HARD/doc-advanced.csv", "Advanced", :blue),
#    FileDetail("$COO_HARD/doc-qmeu_alpha.csv", "DOC-QMEU-A", :green),
#    FileDetail("$COO_HARD/doc-qmeu_beta.csv", "DOC-QMEU-B", :grey),
#    FileDetail("$COO_HARD/tourn-qmeu_alpha.csv", "CFS-QMEU-A", :teal),
#    FileDetail("$COO_HARD/tourn-qmeu_beta.csv", "CFS-QMEU-B", :black),
#    FileDetail("$COO_HARD/p_phc.csv", "P-PHC", :orange),
#    FileDetail("$COO_HARD/p_phc_p_frs.csv", "P-PHC-P-FRS", :purple),
#    FileDetail("$COO_HARD/p_phc_p_uhs.csv", "P-PHC-P-UHS", :violet),
#]
#
#plot_scores(
#    coo_hard_files, 
#    legend=:topleft, 
#    title="Compare-on-One Hard: Five Dimensions", 
#    ylabel="Minimum Dimension Value", 
#    filename="coo_hard",
#    ylims=(-1.0, -1.0),
#    xlims=(0.0, 500.0)
#)
#plot_scores(
#    coo_files, 
#    legend=:topleft, 
#    title="Compare-on-One: Five Dimensions", 
#    ylabel="Minimum Dimension Value", 
#    filename="coo",
#    ylims=(-1.0, -1.0),
#    xlims=(0.0, 500.0)
#)

#plot_scores(
#    fsm_all_files, 
#    legend=:outertopright, title="LPG: Adaptive Complexity", 
#    ylabel="Adaptive Complexity", 
#    filename="fsm_acg_all",
#    ycolumn="modes_complexity",
#    ylims=(0.0, 400.0)
#)
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Adaptive Complexity with Baselines + DOC", 
#    ylabel="Adaptive Complexity", 
#    filename="fsm_acg_doc",
#    ycolumn="modes_complexity",
#    ylims=(0.0, 400.0)
#
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Adaptive Complexity with P-PHC", 
#    ylabel="Adaptive Complexity", 
#    filename="fsm_acg_phc",
#    ycolumn="modes_complexity",
#    ylims=(0.0, 400.0)
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Adaptive Complexity with QueMEU", 
#    ylabel="Adaptive Complexity", 
#    filename="fsm_acg_qmeu",
#    ycolumn="modes_complexity",
#    ylims=(0.0, 400.0)
#)
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Full Complexity with Baselines + DOC", 
#    ylabel="Full Genotype Size", 
#    filename="fsm_full_doc",
#    ycolumn="full_complexity",
#    ylims=(0.0, 400.0)
#
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Full Complexity with P-PHC", 
#    ylabel="Full Genotype Size", 
#    filename="fsm_full_phc",
#    ycolumn="full_complexity",
#    ylims=(0.0, 400.0)
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Full Complexity with QueMEU", 
#    ylabel="Full Genotype Size", 
#    filename="fsm_full_qmeu",
#    ycolumn="full_complexity",
#    ylims=(0.0, 400.0)
#)
#
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with Baselines + DOC", 
#    ylabel="Expected Utility", 
#    filename="fsm_eu_doc",
#    ycolumn="utility_128",
#    ylims=(0.35, 0.66)
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with P-PHC", 
#    ylabel="Expected Utility", 
#    filename="fsm_eu_phc",
#    ycolumn="utility_128",
#    ylims=(0.35, 0.66)
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with QueMEU", 
#    ylabel="Expected Utility", 
#    filename="fsm_eu_qmeu",
#    ycolumn="utility_128",
#    ylims=(0.35, 0.66)
#)
#
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Change with Baselines + DOC", 
#    ylabel="Change", 
#    filename="fsm_change_doc",
#    ycolumn="change",
#    ylims = (0.0, 4.0)
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Change with P-PHC", 
#    ylabel="Change", 
#    filename="fsm_change_phc",
#    ycolumn="change",
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Change with QueMEU", 
#    ylabel="Change", 
#    filename="fsm_change_qmeu",
#    ycolumn="change",
#    ylims = (0.0, 4.0)
#)
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Novelty with Baselines + DOC", 
#    ylabel="Novelty", 
#    filename="fsm_novelty_doc",
#    ycolumn="novelty",
#    ylims = (0.0, 4.0)
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Novelty with P-PHC", 
#    ylabel="Novelty", 
#    filename="fsm_novelty_phc",
#    ycolumn="novelty",
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Novelty with QueMEU", 
#    ylabel="Novelty", 
#    filename="fsm_novelty_qmeu",
#    ycolumn="novelty",
#    ylims = (0.0, 4.0)
#)
#
#plot_scores(
#    fsm_files_doc, 
#    legend=:outertopright, title="LPG: Ecology with Baselines + DOC", 
#    ylabel="Ecology", 
#    filename="fsm_ecology_doc",
#    ycolumn="ecology",
#    #ylims = (0.0, 4.0)
#)
#
#plot_scores(
#    fsm_files_phc, 
#    legend=:outertopright, title="LPG: Ecology with P-PHC", 
#    ylabel="Ecology", 
#    filename="fsm_ecology_phc",
#    ycolumn="ecology",
#)
#
#plot_scores(
#    fsm_files_qmeu, 
#    legend=:outertopright, title="LPG: Ecology with QueMEU", 
#    ylabel="Ecology", 
#    filename="fsm_ecology_qmeu",
#    ycolumn="ecology",
#    #ylims = (0.0, 4.0)
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:bottomright, title="Linguistic Prediction Game: Expected Utility", 
#    ylabel="Expected Utility", 
#    filename="fsm_utility",
#    ycolumn="utility_all"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:bottomright, title="Linguistic Prediction Game: Expected Utility 16", 
#    ylabel="Expected Utility 16", 
#    filename="fsm_utility_16",
#    ycolumn="utility_16"
#)
#
#plot_scores(
#    fsm_all_files, 
#    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs", 
#    ylabel="Expected Utility", 
#    filename="fsm_utility_128",
#    ycolumn="utility_128"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:topleft,
#    title="Linguistic Prediction Game: Full Complexity", 
#    ylabel="Full Complexity", 
#    filename="fsm_full",
#    ycolumn="full_complexity"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:topleft,
#    title="Linguistic Prediction Game: Hopcroft Complexity", 
#    ylabel="Hopcroft Complexity", 
#    filename="fsm_hop",
#    ycolumn="hopcroft_complexity"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:bottomright,
#    title="Linguistic Prediction Game: Change", 
#    ylabel="Change", 
#    filename="fsm_change",
#    ycolumn="change"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:bottomright,
#    title="Linguistic Prediction Game: Novelty", 
#    ylabel="Novelty", 
#    filename="fsm_novelty",
#    ycolumn="novelty"
#)
#plot_scores(
#    fsm_all_files, 
#    legend=:bottomright,
#    title="Linguistic Prediction Game: Two-Species Competitive", 
#    ylabel="Ecology", 
#    filename="fsm_ecology",
#    ycolumn="ecology"
#)

#plot_heatmap(dct_files)