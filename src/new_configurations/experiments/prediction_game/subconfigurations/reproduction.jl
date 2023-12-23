using ...ReproductionConfigurations.Roulette: RouletteReproductionConfiguration
using ...ReproductionConfigurations.Tournament: TournamentReproductionConfiguration
using ...ReproductionConfigurations.Disco: DiscoReproductionConfiguration


const ID_TO_REPRODUCTION_MAP = Dict(
    "roulette" => RouletteReproductionConfiguration,
    "tournament" => TournamentReproductionConfiguration,
    "disco" => DiscoReproductionConfiguration,
)

function load_reproduction(file::File)
    base_path = "configuration/reproducer"
    id = read(file["$base_path/id"])
    type = get(ID_TO_REPRODUCTION_MAP, id, nothing)

    if type === nothing
        error("Unknown reproducer type: $id")
    end
    reproducer = load_type(type, file, base_path)
    return reproducer
end

function get_reproduction(id::String; kwargs...)
    type = get(ID_TO_REPRODUCTION_MAP, id, nothing)
    if type === nothing
        error("Unknown reproducer type: $id")
    end
    reproducer = type(; id = id, kwargs...)
    return reproducer
end
