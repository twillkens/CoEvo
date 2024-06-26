export create_archivers, NumbersGameArchiver, archive!, collect_species_data
export calculate_average_minimum_gene, calculate_num_max_gene_at_index, calculate_average_gene_value_at_index


import ....Interfaces: archive!
using DataFrames
using CSV
using Serialization
using ....Abstract
using ....Interfaces
using ...Phenotypes.GnarlNetworks
using ...Genotypes.GnarlNetworks

struct CPTArchiver{G <: GnarlNetworkPhenotype} <: Archiver 
    data::DataFrame
    samples::Vector{G}
end

function CPTArchiver(configuration::MaxSolveConfiguration)
    save_file = get_save_file(configuration)
    if isfile(save_file)
        data = CSV.read(save_file, DataFrame)
    else
        data = DataFrame(
            task = String[],
            domain = String[],
            trial = Int[], 
            algorithm = String[],
            learner_algorithm = String[],
            test_algorithm = String[],
            generation = Int[], 
            fitness = Float64[], 
            utility = Float64[], 
            full_size = Int[],
            min_size = Int[],
            seed = Int[]
        )
    end
    genotype_creator = RandomFCGnarlNetworkGenotypeCreator(2, 8, 1)
    genotypes = create_genotypes(genotype_creator, Random.GLOBAL_RNG, BasicCounter(1), 10_000)
    phenotypes = [
        create_phenotype(GnarlNetworkPhenotypeCreator(scaled_tanh, x -> x), 1, genotype)
        for genotype in genotypes
    ]
    return CPTArchiver(data, phenotypes)
end


function get_utility(
    learner::GnarlNetworkPhenotype, 
    tests::Vector{<:GnarlNetworkPhenotype},
    domain_name::String, 
    episode_length::Int
)
    domain = PredictionGameDomain(domain_name)
    environment_creator = ContinuousPredictionGameEnvironmentCreator(domain, episode_length, 0)
    fitness = 0.0
    for test in tests
        environment = create_environment(environment_creator, learner, test)
        while is_active(environment)
            step!(environment)
        end
        outcome_set = get_outcome_set(environment)
        fitness += outcome_set[1]
        reset!(learner)
        reset!(test)
    end
    return fitness / length(tests)
end

function get_utility(
    learner::Individual, 
    tests::Vector{<:GnarlNetworkPhenotype}, 
    domain_name::String,
    episode_length::Int
)
    return get_utility(learner.phenotype, tests, domain_name, episode_length)
end

function archive!(archiver::CPTArchiver, state::State)
    elite_fitness = -1
    elite = nothing
    for learner in [state.ecosystem.learner_population ; state.ecosystem.learner_children]
        p = state.ecosystem.payoff_matrix
        fitness = sum(p[learner.id, :])
        if fitness > elite_fitness
            elite_fitness = fitness
            elite = learner
        end
    end
    utility = get_utility(
        elite, archiver.samples, state.configuration.domain, state.configuration.episode_length
    )
    #elite_minimum_gene = minimum(elite.genotype.genes)
    info = (
        task = state.configuration.task, 
        domain = state.configuration.domain,
        trial = state.configuration.id, 
        algorithm = state.configuration.algorithm,
        learner_algorithm = state.configuration.learner_algorithm,
        test_algorithm = state.configuration.test_algorithm,
        generation = state.generation, 
        fitness = elite_fitness,
        utility = utility,
        full_size = length(elite.genotype.connections),
        min_size = length(minimize(elite.genotype).connections),
        seed = state.configuration.seed
    )
    push!(archiver.data, info)
    save_file = "$(state.configuration.archive_directory)/data.csv"
    CSV.write(save_file, archiver.data)
    #learner_population_path = "$(state.configuration.archive_directory)/learner_population/$(state.generation).jls"
    #serialize(learner_population_path, state.ecosystem.learner_population)
    #test_population_path = "$(state.configuration.archive_directory)/test_population/$(state.generation).jls"
    #serialize(test_population_path, state.ecosystem.test_population)
end