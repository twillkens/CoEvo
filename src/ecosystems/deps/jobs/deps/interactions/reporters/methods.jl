struct TheTwoVectorsWithGreatestSineOfSums <: Metric end
struct TheVectorWithAverageClosestToPi <: Metric end

function calculate_sine_of_sumsalculate_sine_of_sums(
    observations::Vector{Observation{TheVectorWithAverageClosestToPi, Vector{Float64}}}
)
    sine_values = [sin(sum(obs.data)) for obs in observations]
    return sine_values
end

function create_report(
    reporter::BasicDomainReporter{TheTwoVectorsWithGreatestSineOfSums},
    gen::Int,
    to_print::Bool,
    to_save::Bool,
    domain_id::String,
    observations::Vector{Observation{TheVectorWithAverageClosestToPi, Vector{Float64}}}
)
    
    # Calculate the sine of sums for all observations
    sine_values = calculate_sine_of_sums(observations)

    # Find the two with the greatest sine values
    sorted_indices = sortperm(sine_values, rev=true)
    top_two = observations[sorted_indices[1:2]]

    # Create a report
    report = """
    Report for Domain ID: $domain_id
    Generation: $gen
    Description: $(reporter.description)

    Top Two Observations with Greatest Sine of Sums:
    1. Value: $(top_two[1].value), Data: $(top_two[1].data)
    2. Value: $(top_two[2].value), Data: $(top_two[2].data)
    """

    # Print report if needed
    if to_print
        println(report)
    end

    # Save report if needed
    if to_save
        filename = "report_$domain_id_$gen.txt"
        open(filename, "w") do file
            write(file, report)
        end
        println("Report saved as $filename")
    end

    return report
end