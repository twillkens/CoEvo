module Helpers

export make_counters, make_random_number_generator, make_performer, make_recombiner
export make_replacer, make_matchmaker, evolve!

using JLD2: @save
using StableRNGs: StableRNG
using ..Configurations.Abstract: Configuration
using ..Configurations.Interfaces: make_ecosystem_creator
using ...Ecosystems.Performers.Concrete.Cache: CachePerformer
using ...Ecosystems.Utilities.Counters: Counter
using ...Ecosystems.Interactions.MatchMakers.AllvsAll: AllvsAllMatchMaker
using ...Ecosystems.Species.Replacers.Types.Truncation: TruncationReplacer
using ...Ecosystems.Species.Recombiners.Types.Clone: CloneRecombiner


import ...Ecosystems.Interfaces: evolve!

function make_counters(configuration::Configuration)
    individual_id_counter = Counter(configuration.individual_id_counter_state)
    gene_id_counter = Counter(configuration.gene_id_counter_state)
    return individual_id_counter, gene_id_counter
end

function make_random_number_generator(configuration::Configuration)
    seed = configuration.seed
    random_number_generator = configuration.random_number_generator
    if random_number_generator === nothing
        random_number_generator = StableRNG(seed)
    end
    return random_number_generator
end

function make_performer(configuration::Configuration)
    performer = configuration.performer
    if performer == :cache
        return CachePerformer(n_workers = configuration.n_workers)
    else
        throw(ArgumentError("Unrecognized performer: $performer"))
    end
end

function make_recombiner(configuration::Configuration)
    recombiner = configuration.recombiner
    if recombiner == :clone
        return CloneRecombiner()
    else
        throw(ArgumentError("Unrecognized recombiner: $recombiner"))
    end
end
function make_replacer(configuration::Configuration)
    replacer = configuration.replacer
    if replacer == :truncation
        return TruncationReplacer(n_truncate = configuration.n_truncate)
    else
        throw(ArgumentError("Unrecognized replacer: $replacer"))
    end
end

function make_matchmaker(configuration::Configuration)
    matchmaker = configuration.matchmaker
    if matchmaker == :all_vs_all
        return AllvsAllMatchMaker(cohorts = configuration.cohorts)
    else
        throw(ArgumentError("Unrecognized matchmaker: $matchmaker"))
    end
end

function evolve!(configuration::Configuration; n_generations::Int = 100)
    ecosystem_creator = make_ecosystem_creator(configuration)
    archive_path = ecosystem_creator.archiver.archive_path
    dir_path = dirname(archive_path)

    # Check if the file exists
    if isfile(archive_path)
        throw(ArgumentError("File already exists: $archive_path"))
    end
    mkpath(dir_path)
    @save archive_path configuration = configuration
    ecosystem = evolve!(ecosystem_creator, n_generations = n_generations)
    return ecosystem
end

end