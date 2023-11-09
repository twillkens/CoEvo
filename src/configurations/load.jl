export load_configuration

function load_configuration(file::File) 
    configuration_dict = Dict(
        "PredictionGameConfiguration" => PredictionGame.PredictionGameConfiguration,
    )
    # Ensure the group "configuration" exists
    config_group = file["configuration"]

    # Extract fields and construct the object
    kwargs = Dict{Symbol, Any}()
    for field in fieldnames(PredictionGameConfiguration)
        kwargs[field] = config_group[string(field)]
    end

    configuration_name = config_group["configuration_type"]
    configuration_type = configuration_dict[configuration_name]
    configuration = configuration_type(; kwargs...)
    
    return configuration
end
