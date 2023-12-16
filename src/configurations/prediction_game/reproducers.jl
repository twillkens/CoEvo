export Reproducer, RouletteReproducer, DiscoReproducer, load_reproducer, get_reproducer
export make_evaluator, make_replacer, make_selector, archive!

abstract type Reproducer end

function get_n_individuals(reproducer::Reproducer)
    throw(ErrorException("get_n_individuals not implemented for reproducer of type $(typeof(reproducer))"))
end

function get_maximum_fitness(reproducer::Reproducer, topology::Topology)
    n_others = get_n_species(topology) - 1
    n_individuals = get_n_individuals(reproducer)
    maximum_fitness = n_individuals * n_others
    return maximum_fitness
end

function make_half_truncator(reproducer::Reproducer)
    n_individuals = get_n_individuals(reproducer)
    n_truncate = n_individuals ÷ 2
    truncator = TruncationReplacer(n_truncate = n_truncate)
    return truncator
end

struct RouletteReproducer <: Reproducer
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
end

get_n_individuals(
    reproducer::RouletteReproducer
) = reproducer.n_population + reproducer.n_children

function RouletteReproducer(;
    id::String,
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    kwargs...
)
    reproducer = RouletteReproducer(id, n_species, n_population, n_children)
    return reproducer
end

function archive!(reproducer::RouletteReproducer, file::File) 
    base_path = "configuration/reproducer"
    file["$base_path/id"] = "roulette"
    file["$base_path/n_species"] = reproducer.n_species
    file["$base_path/n_population"] = reproducer.n_population
    file["$base_path/n_children"] = reproducer.n_children
end

function make_evaluator(::RouletteReproducer, ::BasicTopology)
    evaluator = ScalarFitnessEvaluator()
    return evaluator
end

function make_evaluator(reproducer::RouletteReproducer, topology::AdaptiveArchiveTopology)
    evaluator = AdaptiveArchiveEvaluator(
        non_archive_evaluator = make_evaluator(reproducer, topology.basic_topology),
        full_evaluator = make_evaluator(reproducer, topology.basic_topology),
    )
    return evaluator
end

make_replacer(reproducer::RouletteReproducer) = make_half_truncator(reproducer)

make_selector(
    reproducer::RouletteReproducer
) = FitnessProportionateSelector(n_parents = reproducer.n_population)


#########################################

struct TournamentReproducer <: Reproducer
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
    tournament_size::Int
end

get_n_individuals(
    reproducer::TournamentReproducer
) = reproducer.n_population + reproducer.n_children

function TournamentReproducer(;
    id::String,
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    tournament_size::Int = 3,
    kwargs...
)
    reproducer = TournamentReproducer(id, n_species, n_population, n_children, tournament_size)
    return reproducer
end

function archive!(reproducer::TournamentReproducer, file::File) 
    base_path = "configuration/reproducer"
    file["$base_path/id"] = "roulette"
    file["$base_path/n_species"] = reproducer.n_species
    file["$base_path/n_population"] = reproducer.n_population
    file["$base_path/n_children"] = reproducer.n_children
    file["$base_path/tournament_size"] = reproducer.tournament_size
end

function make_evaluator(reproducer::TournamentReproducer, topology::Topology)
    maximum_fitness = get_maximum_fitness(reproducer, topology)
    evaluator = ScalarFitnessEvaluator(maximum_fitness = maximum_fitness)
    return evaluator
end

make_replacer(reproducer::TournamentReproducer) = make_half_truncator(reproducer)

make_selector(reproducer::TournamentReproducer) = TournamentSelector(
    n_parents = reproducer.n_population, tournament_size = reproducer.tournament_size
)

################################


struct DiscoReproducer <: Reproducer
    id::String
    n_species::Int
    n_population::Int
    n_children::Int
    tournament_size::Int
    max_clusters::Int
    distance_method::String
end

get_n_individuals(
    reproducer::DiscoReproducer
) = reproducer.n_population + reproducer.n_children

function DiscoReproducer(;
    id::String = "disco",
    n_species::Int = 2, 
    n_population::Int = 10, 
    n_children::Int = 10, 
    tournament_size::Int = 3,
    max_clusters::Int = 5,
    distance_method::String = "disco_average",
    kwargs...
)
    reproducer = DiscoReproducer(
        id,
        n_species,
        n_population,
        n_children,
        tournament_size,
        max_clusters,
        distance_method,
    )
    return reproducer
end

function archive!(reproducer::DiscoReproducer, file::File) 
    base_path = "configuration/reproducer"
    file["$base_path/id"] = "disco"
    file["$base_path/n_species"] = reproducer.n_species
    file["$base_path/n_population"] = reproducer.n_population
    file["$base_path/n_children"] = reproducer.n_children
    file["$base_path/tournament_size"] = reproducer.tournament_size
    file["$base_path/max_clusters"] = reproducer.max_clusters
    file["$base_path/distance_method"] = reproducer.distance_method
end

function make_evaluator(reproducer::DiscoReproducer, ::BasicTopology)
    evaluator = NSGAIIEvaluator(
        maximize = true, 
        perform_disco = true, 
        max_clusters = reproducer.max_clusters,
        scalar_fitness_evaluator = ScalarFitnessEvaluator(),
        distance_method = :disco_average
    )
    return evaluator
end

function make_evaluator(reproducer::DiscoReproducer, topology::AdaptiveArchiveTopology)
    evaluator = AdaptiveArchiveEvaluator(
        non_archive_evaluator = ScalarFitnessEvaluator(),
        full_evaluator = make_evaluator(reproducer, topology.basic_topology),
    )
    return evaluator
end

make_replacer(reproducer::DiscoReproducer) = make_half_truncator(reproducer)

function make_selector(reproducer::DiscoReproducer)
    selector = TournamentSelector(
        n_parents = reproducer.n_population, 
        tournament_size = reproducer.tournament_size
    )
    return selector
end

const ID_TO_REPRODUCER_MAP = Dict(
    "roulette" => RouletteReproducer,
    "disco" => DiscoReproducer,
)

function load_reproducer(file::File)
    base_path = "configuration/reproducer"
    id = read(file["$base_path/id"])
    type = get(ID_TO_REPRODUCER_MAP, id, nothing)

    if type === nothing
        error("Unknown reproducer type: $id")
    end
    reproducer = load_type(type, file, base_path)
    return reproducer
end

function get_reproducer(id::String; kwargs...)
    type = get(ID_TO_REPRODUCER_MAP, id, nothing)
    if type === nothing
        error("Unknown reproducer type: $id")
    end
    reproducer = type(; id = id, kwargs...)
    return reproducer
end
