using CSV
using DataFrames
using Glob

function combine_files(filepaths::Vector{String}, output_filepath::String)
    all_data = DataFrame()
    trial_offset = 0

    for filepath in filepaths
        println("Processing file: $filepath")
        df = load_and_adjust_trials(filepath, trial_offset)

        if !isempty(df)
            all_data = vcat(all_data, df)
            trial_offset += maximum(df.trial)
        end
    end

    if !isempty(all_data)
        CSV.write(output_filepath, all_data)
        println("Combined data saved to $output_filepath")
    else
        println("No data was combined; the output file was not created.")
    end
end

function load_and_adjust_trials(filepath::String, trial_offset::Int)
    println("Loading $filepath with trial offset $trial_offset")
    df = CSV.read(filepath, DataFrame)

    if "trial" in names(df)
        df.trial .+= 0
    else
        println("The file $filepath does not contain a 'trial' column.")
        return DataFrame()
    end

    return df
end

function consolidate_csv_files(experiment::String, patterns::Vector{String}, output_dir::String)
    for pattern in patterns
        println("Pattern: $pattern")
        filepaths = glob(pattern, "fsm_data")
        println("Found filepaths: $filepaths")
        if isempty(filepaths)
            println("No files found for pattern: $pattern")
            continue
        end

        output_filename = "$(experiment)-$(replace(basename(pattern), r"[\\*\\.]+" => "")).csv"
        output_filepath = joinpath(output_dir, output_filename)
        println("Output filepath: $output_filepath")
        combine_files(filepaths, output_filepath)
    end
end

function main()
    output_dir = "FSM-DATA"
    mkpath(output_dir)

    patterns = [
        "fsm-advanced-CompareOnAll-*.csv",
        "fsm-qmeu-CompareOnAll-*.csv",
        "fsm-standard-CompareOnAll-*.csv",
        "fsm-roulette-CompareOnAll-*.csv",
        "fsm-control-CompareOnAll-*.csv"
    ]

    consolidate_csv_files("fsm_data", patterns, output_dir)
end

main()
