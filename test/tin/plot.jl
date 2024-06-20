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

const LOG_DIR = "logs/QUEMEU-DATA"

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


function plot_fitnesses(files::Vector{FileDetail})
    p = plot(legend=:bottomright, xlabel="Generation", ylabel="Fitness", 
        title="Density Classification Task: Fitness"
    )

    for file in files
        # Read the CSV file
        data = CSV.read(file.filepath, DataFrame)

        # Process the dataset
        grouped = groupby(data, :generation)
        
        # Initialize vectors for generations, means, and confidence intervals
        generations = Int[]
        means = Float64[]
        lower_cis = Float64[]
        upper_cis = Float64[]

        for group in grouped
            gen = group[1, :generation]  # Extracting the generation value
            group_scores = group[:, :fitness]  # Extracting scores for this generation

            push!(generations, gen)
            push!(means, mean(group_scores))

            ci = get_bootstrapped_confidence_intervals(group_scores, DEFAULT_CONFIDENCE)
            push!(lower_cis, ci["lower_confidence"])
            push!(upper_cis, ci["upper_confidence"])
        end

        # Plotting data from the current file
        plot!(p, generations, means, ribbon = (means .- lower_cis, upper_cis .- means), fillalpha = 0.35, 
              label=file.label, color=file.color)
    end

    savefig(p, "Fitnesses.png")
    display(p)
end


# Example usage:
function combine_files_2(experiment::String)
    combine_files([
        "$LOG_DIR/$experiment-1.csv",
        "$LOG_DIR/$experiment-2.csv",
    ], "$LOG_DIR/$experiment.csv")
end

function combine_files_3(experiment::String)
    combine_files([
        "$experiment-1.csv",
        "$experiment-2.csv",
        "$experiment-3.csv",
    ], "$experiment.csv")
end
function combine_files_5(experiment::String)
    combine_files([
        "$experiment-1.csv",
        "$experiment-2.csv",
        "$experiment-3.csv",
        "$experiment-4.csv",
        "$experiment-5.csv",
    ], "$experiment.csv")
end
using CSV
using DataFrames


function load_and_adjust_trials(filepath::String, trial_offset::Int)
    df = CSV.read(filepath, DataFrame)

    # Check and adjust the 'trial' column if it exists
    if "trial" in names(df)
        df.trial .+= trial_offset
    else
        println("The file $filepath does not contain a 'trial' column.")
        # You might want to return here or handle the case differently depending on your needs
        return DataFrame()
    end

    return df
end

function combine_files(filepaths::Vector{String}, output_filepath::String)
    all_data = DataFrame()
    trial_offset = 0

    for filepath in filepaths
        df = load_and_adjust_trials(filepath, trial_offset)

        # Only combine if the dataframe is not empty (which happens if there's no 'trial' column)
        if !isempty(df)
            all_data = vcat(all_data, df)
            trial_offset = maximum(df.trial)
        end
    end

    # Save only if we have data to save
    if !isempty(all_data)
        CSV.write(output_filepath, all_data)
        println("Combined data saved to $output_filepath")
    else
        println("No data was combined; the output file was not created.")
    end
end

function combine_files(dirpath::String, output_filepath::String, max_generation::Int = 10_000)
    filepaths = glob("*.csv", dirpath)
    all_data = DataFrame()
    trial_offset = 0

    for filepath in filepaths
        df = load_and_adjust_trials(filepath, trial_offset)
        df = filter(row -> row.generation <= max_generation, df)

        # Only combine if the dataframe is not empty (which happens if there's no 'trial' column)
        if !isempty(df)
            all_data = vcat(all_data, df)
            #trial_offset = maximum(df.trial)
        end
    end

    # Save only if we have data to save
    if !isempty(all_data)
        CSV.write(output_filepath, all_data)
        println("Combined data saved to $output_filepath")
    else
        println("No data was combined; the output file was not created.")
    end
end


using CSV
using DataFrames
using Plots

function plot_histograms(files::Vector{FileDetail})
    for file in files
        # Read the CSV file
        data = CSV.read(file.filepath, DataFrame)

        # Check if 'score' column exists
        if "score" in names(data)
            # Plot the histogram
            p = histogram(data[!, "score"], bins=100, xlims=(0, 1), 
                          label=file.label, alpha=0.6, color=file.color,
                          title="Histogram of Scores for $(file.label)", xlabel="Score", ylabel="Frequency",
                          size = (800, 400))

            # Save the plot to a file
            savefig(p, "Histogram_$(file.label).png")
        else
            println("The file $(file.filepath) does not contain a 'score' column.")
        end
    end
end

function plot_histograms(files::Vector{FileDetail})
    for file in files
        # Read the CSV file
        data = CSV.read(file.filepath, DataFrame)

        # Ensure the necessary columns exist
        if all(col -> col in names(data), ["trial", "generation", "score"])
            # Group by trial and find the final generation's scores for each trial
            grouped_data = groupby(data, :trial)
            final_gen_scores = Float64[]

            for group in grouped_data
                # Find the maximum generation number in the current group (trial)
                max_generation = maximum(group[!, :generation])
                # Filter to get the scores from the final generation
                append!(final_gen_scores, group[group.generation .== max_generation, :score])
            end

            # Plot the histogram using the scores from final generations of all trials
            p = histogram(final_gen_scores, bins=30, xlims=(0, 1),
                          label="Scores from Final Generations", alpha=0.6, color="blue",
                          title="Histogram of Scores from Final Generations", xlabel="Score", ylabel="Frequency",
                          size=(400, 400))

            # Save the plot to a file
            savefig(p, "Histogram_Final_Generations_$(file.label).png")
        else
            println("The file $(file.filepath) does not contain the necessary columns ('trial', 'generation', or 'score').")
        end
    end
end

using CSV, DataFrames, Plots


using CSV, DataFrames, Plots

function plot_heatmap(files::Vector{FileDetail})
    for file in files
        # Read the CSV file
        data = CSV.read(file.filepath, DataFrame)

        # Ensure the necessary columns exist
        if all(col -> col in names(data), ["trial", "generation", "score"])
            # Pivot the data to have trials as rows and generations as columns with scores as values
            pivoted_data = unstack(data, :trial, :generation, :score)

            # Replace missing with 0.0 for the whole DataFrame
            for col in names(pivoted_data)[2:end]  # Skip the first column (trial)
                replace!(pivoted_data[!, col], missing => 0.0)
            end

            # Sparsely label the x (generations) and y (trials) axes to avoid overlap
            x_labels = [1, 50, 100, 150, 200]
            x_ticks = [i for i in x_labels]
            y_labels = reverse([1, 10, 20, 30, 40, 50, 60, 80])
            y_ticks = [i for i in y_labels]

            # Plot the heatmap with a grayscale color map
            p = heatmap(Array(pivoted_data[:, 2:end]),  # Convert DataFrame to Array, excluding trial labels
                        color=:grays,
                        clim=(0, 1),  # Ensure the color range covers from 0 to 1
                        colorbar_title="Score",
                        aspect_ratio=:auto,
                        title="Accuracy Heatmap for $(file.label)",
                        xlabel="Generation",
                        ylabel="Trial",
                        xticks=(x_ticks, string.(x_labels)),  # Label generations sparsely
                        yticks=(y_ticks, string.(y_labels)),  # Label trials sparsely
                        size=(600, 400))

            # Save the plot to a file
            savefig(p, "$LOG_DIR/Heatmap_Scores_$(file.label).png")
        else
            println("The file $(file.filepath) does not contain the necessary columns ('trial', 'generation', or 'score').")
        end
    end
end


# Function to load data from files and extract scores for a specific generation across all trials
function load_and_prepare_data(file_details::Vector{FileDetail}, target_generation::Int)
    data_dict = Dict{String, Vector{Float64}}()
    
    for file_detail in file_details
        df = CSV.read(file_detail.filepath, DataFrame)
        
        # Filter data to only include the specific generation
        filtered_df = filter(row -> row.generation == target_generation, df)
        
        # Assuming 'trial' column exists to uniquely identify each trial at the target generation
        # Extract the 'score' column values into a Vector{Float64}
        scores = Vector{Float64}(filtered_df.score)
        
        # Ensure that we get exactly 60 scores, one for each trial
        if length(scores) != 60
            error("Expected 60 scores for each trial at generation $target_generation, got $(length(scores))")
        end
        
        # Insert the scores vector into the dictionary with the corresponding label
        data_dict[file_detail.label] = scores
    end
    
    return data_dict
end

include("analyze.jl")
# Example function to run analysis on data extracted for a specific generation
function run_file_analysis(file_details::Vector{FileDetail}, generation::Int, control_label::String)
    data = load_and_prepare_data(file_details, generation)
    results = run_analysis(control_label, data)
    return results
end

#dct_files = [
#    FileDetail("$LOG_DIR/dct-standard.csv", "Standard", :red),
#    FileDetail("$LOG_DIR/dct-advanced.csv", "Advanced", :blue),
#    FileDetail("$LOG_DIR/dct-qmeu.csv", "QueMEU", :green),
#]
#
#coa_files = [
#    FileDetail("$LOG_DIR/numbers_game-standard-CompareOnAll.csv", "Standard", :red),
#    FileDetail("$LOG_DIR/numbers_game-advanced-CompareOnAll.csv", "Advanced", :blue),
#    FileDetail("$LOG_DIR/numbers_game-qmeu-CompareOnAll.csv", "QueMEU", :green),
#]
#
#coo_files = [
#    FileDetail("$LOG_DIR/numbers_game-standard-CompareOnOne.csv", "Standard", :red),
#    FileDetail("$LOG_DIR/numbers_game-advanced-CompareOnOne.csv", "Advanced", :blue),
#    FileDetail("$LOG_DIR/numbers_game-qmeu-CompareOnOne.csv", "QueMEU", :green),
#]
#
#fsm_files = [
#    FileDetail("$LOG_DIR/fsm-control.csv", "Control", :orange),
#    FileDetail("$LOG_DIR/fsm-roulette.csv", "Roulette", :purple),
#    FileDetail("$LOG_DIR/fsm-standard.csv", "Standard", :red),
#    FileDetail("$LOG_DIR/fsm-advanced.csv", "Advanced", :blue),
#    FileDetail("$LOG_DIR/fsm-qmeu.csv", "QueMEU", :green),
#]
#
#fsm_simple_files = [
#    FileDetail("$LOG_DIR/fsm-standard.csv", "Standard", :red),
#    FileDetail("$LOG_DIR/fsm-advanced.csv", "Advanced", :blue),
#    FileDetail("$LOG_DIR/fsm-qmeu.csv", "QueMEU", :green),
#]

combine_files("all_fsm_trials/control", "logs/fsm/control.csv")
combine_files("all_fsm_trials/doc_adv", "logs/fsm/doc_adv.csv")
combine_files("all_fsm_trials/doc_qmeu_alpha", "logs/fsm/doc_qmeu_alpha.csv")
combine_files("all_fsm_trials/doc_qmeu_beta", "logs/fsm/doc_qmeu_beta.csv")
combine_files("all_fsm_trials/doc_std", "logs/fsm/doc_std.csv")
combine_files("all_fsm_trials/p_phc", "logs/fsm/p_phc.csv")
combine_files("all_fsm_trials/p_phc_frs", "logs/fsm/p_phc_frs.csv")
combine_files("all_fsm_trials/p_phc_uhs", "logs/fsm/p_phc_uhs.csv")
combine_files("all_fsm_trials/roulette", "logs/fsm/roulette.csv")
combine_files("all_fsm_trials/cfs_qmeu_alpha", "logs/fsm/cfs_qmeu_alpha.csv")
combine_files("all_fsm_trials/cfs_qmeu_beta", "logs/fsm/cfs_qmeu_beta.csv")
combine_files("all_fsm_trials/cfs_qmeu_gamma", "logs/fsm/cfs_qmeu_gamma.csv")

fsm_all_files = [
    FileDetail("logs/fsm/control.csv", "CTRL", :red),
    FileDetail("logs/fsm/roulette.csv", "ROUL", :blue),
    FileDetail("logs/fsm/doc_std.csv", "DOC-STD", :green),
    FileDetail("logs/fsm/doc_adv.csv", "DOC-ADV", :brown),
    FileDetail("logs/fsm/doc_qmeu_alpha.csv", "DOC-QMEU-A", :purple),
    FileDetail("logs/fsm/doc_qmeu_beta.csv", "DOC-QMEU-B", :orange),
    FileDetail("logs/fsm/cfs_qmeu_beta.csv", "CFS-QMEU-B", :grey),
    FileDetail("logs/fsm/p_phc.csv", "P-PHC", :black),
    FileDetail("logs/fsm/p_phc_frs.csv", "P-PHC-P-FRS", :cyan),
    FileDetail("logs/fsm/p_phc_uhs.csv", "P-PHC-P-UHS", :violet),
    #FileDetail("qmeu_gamma.csv", "QueMEU-Gamma", :purple),
]

fsm_files_doc = [
    FileDetail("logs/fsm/control.csv", "CTRL", :red),
    FileDetail("logs/fsm/roulette.csv", "ROUL", :blue),
    FileDetail("logs/fsm/doc_std.csv", "DOC-STD", :green),
    FileDetail("logs/fsm/doc_adv.csv", "DOC-ADV", :brown),
]

fsm_files_phc = [
    FileDetail("logs/fsm/control.csv", "CTRL", :red),
    FileDetail("logs/fsm/p_phc.csv", "P-PHC", :black),
    FileDetail("logs/fsm/p_phc_frs.csv", "P-PHC-P-FRS", :cyan),
    FileDetail("logs/fsm/p_phc_uhs.csv", "P-PHC-P-UHS", :violet),
]

fsm_files_qmeu = [
    FileDetail("logs/fsm/control.csv", "CTRL", :red),
    FileDetail("logs/fsm/doc_qmeu_alpha.csv", "DOC-QMEU-A", :purple),
    FileDetail("logs/fsm/doc_qmeu_beta.csv", "DOC-QMEU-B", :orange),
    FileDetail("logs/fsm/cfs_qmeu_alpha.csv", "CFS-QMEU-A", :grey),
    FileDetail("logs/fsm/cfs_qmeu_beta.csv", "CFS-QMEU-B", :blue),
    FileDetail("logs/fsm/cfs_qmeu_gamma.csv", "CFS-QMEU-G", :green),
    #FileDetail("qmeu_gamma.csv", "QueMEU-Gamma", :purple),
]

#plot_scores(dct_files, title="Density Classification Task: N = 149", ylabel="Accuracy", filename="dct")
#plot_scores(coa_files, legend=:topleft, title="Compare-on-All: Five Dimensions", ylabel="Minimum Dimension Value", filename="coa")
#plot_scores(coo_files, legend=:topleft, title="Compare-on-One: Five Dimensions", ylabel="Minimum Dimension Value", filename="coo")
#plot_scores(
#    fsm_files, 
#    legend=:topleft, title="Linguistic Prediction Game: Two-Species Competitive", 
#    ylabel="Elite Learner/Evader Hopcroft Complexity", 
#    filename="fsm"
#)
#plot_scores(
#    fsm_simple_files, 
#    legend=:topleft, title="Linguistic Prediction Game: Two-Species Competitive", 
#    ylabel="Elite Learner/Evader Hopcroft Complexity", 
#    filename="fsm_simple"
#)
function plot_scores(
    files::Vector{FileDetail}; 
    title::String="Density Classification Task: Accuracy",
    legend::Symbol=:bottomright,
    ylabel::String="Accuracy",
    filename::String="dct",
    ycolumn::String="score",
    ylims::Tuple{Float64, Float64}=(-1.0, -1.0),
)
    p = plot(legend=legend, xlabel="Generation", ylabel=ylabel, title=title)
    for file in files
        # Read the CSV file
        data = CSV.read(file.filepath, DataFrame)
         if ylims ==  (-1.0, -1.0)
            ylims = nothing
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
        plot!(p, generations, means, ribbon = (means .- lower_cis, upper_cis .- means), fillalpha = 0.35, 
              label=file.label, color=file.color, size=(900, 500), 
              leftmargin=10mm, bottommargin=10mm, rightmargin=10mm, topmargin=10mm,
                ylims=ylims
        )
    end

    savefig(p, "$filename.png")
    display(p)
end

plot_scores(
    fsm_all_files, 
    legend=:outertopright, title="LPG: Adaptive Complexity", 
    ylabel="Adaptive Complexity", 
    filename="fsm_acg_all",
    ycolumn="modes_complexity",
    ylims=(0.0, 400.0)
)

plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Adaptive Complexity with Baselines + DOC", 
    ylabel="Adaptive Complexity", 
    filename="fsm_acg_doc",
    ycolumn="modes_complexity",
    ylims=(0.0, 400.0)

)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Adaptive Complexity with P-PHC", 
    ylabel="Adaptive Complexity", 
    filename="fsm_acg_phc",
    ycolumn="modes_complexity",
    ylims=(0.0, 400.0)
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Adaptive Complexity with QueMEU", 
    ylabel="Adaptive Complexity", 
    filename="fsm_acg_qmeu",
    ycolumn="modes_complexity",
    ylims=(0.0, 400.0)
)

plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Full Complexity with Baselines + DOC", 
    ylabel="Full Genotype Size", 
    filename="fsm_full_doc",
    ycolumn="full_complexity",
    ylims=(0.0, 400.0)

)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Full Complexity with P-PHC", 
    ylabel="Full Genotype Size", 
    filename="fsm_full_phc",
    ycolumn="full_complexity",
    ylims=(0.0, 400.0)
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Full Complexity with QueMEU", 
    ylabel="Full Genotype Size", 
    filename="fsm_full_qmeu",
    ycolumn="full_complexity",
    ylims=(0.0, 400.0)
)


plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with Baselines + DOC", 
    ylabel="Expected Utility", 
    filename="fsm_eu_doc",
    ycolumn="utility_128",
    ylims=(0.35, 0.66)
)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with P-PHC", 
    ylabel="Expected Utility", 
    filename="fsm_eu_phc",
    ycolumn="utility_128",
    ylims=(0.35, 0.66)
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Expected Utility vs. 10k Size 128 FSMs with QueMEU", 
    ylabel="Expected Utility", 
    filename="fsm_eu_qmeu",
    ycolumn="utility_128",
    ylims=(0.35, 0.66)
)


plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Change with Baselines + DOC", 
    ylabel="Change", 
    filename="fsm_change_doc",
    ycolumn="change",
    ylims = (0.0, 4.0)
)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Change with P-PHC", 
    ylabel="Change", 
    filename="fsm_change_phc",
    ycolumn="change",
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Change with QueMEU", 
    ylabel="Change", 
    filename="fsm_change_qmeu",
    ycolumn="change",
    ylims = (0.0, 4.0)
)

plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Novelty with Baselines + DOC", 
    ylabel="Novelty", 
    filename="fsm_novelty_doc",
    ycolumn="novelty",
    ylims = (0.0, 4.0)
)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Novelty with P-PHC", 
    ylabel="Novelty", 
    filename="fsm_novelty_phc",
    ycolumn="novelty",
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Novelty with QueMEU", 
    ylabel="Novelty", 
    filename="fsm_novelty_qmeu",
    ycolumn="novelty",
    ylims = (0.0, 4.0)
)

plot_scores(
    fsm_files_doc, 
    legend=:outertopright, title="LPG: Ecology with Baselines + DOC", 
    ylabel="Ecology", 
    filename="fsm_ecology_doc",
    ycolumn="ecology",
    #ylims = (0.0, 4.0)
)

plot_scores(
    fsm_files_phc, 
    legend=:outertopright, title="LPG: Ecology with P-PHC", 
    ylabel="Ecology", 
    filename="fsm_ecology_phc",
    ycolumn="ecology",
)

plot_scores(
    fsm_files_qmeu, 
    legend=:outertopright, title="LPG: Ecology with QueMEU", 
    ylabel="Ecology", 
    filename="fsm_ecology_qmeu",
    ycolumn="ecology",
    #ylims = (0.0, 4.0)
)
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