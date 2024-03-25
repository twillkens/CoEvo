module MaxSolve

export MaxSolveConfiguration, get_ecosystem_creator, create_reproducer, create_reproducers
export create_simulator, create_evaluator, create_archivers

import ....Interfaces: create_reproducers, create_simulator, create_evaluators, create_archivers
import ....Interfaces: get_ecosystem_creator
using ...Mutators.Vectors: NumbersGameVectorMutator
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Individuals.Basic
using ...Phenotypes.Vectors: NumbersGamePhenotypeCreator
using ...Genotypes.Vectors
using ...Selectors.Identity
using ...Recombiners.Clone
using ...Ecosystems.MaxSolve: MaxSolveEcosystemCreator
using ...Evaluators.Null: NullEvaluator
using ....Abstract

include("imports.jl")

Base.@kwdef struct MaxSolveConfiguration <: Configuration
    id::Int = 1
    seed::Int = 42
    n_generations::Int = 5
    n_workers::Int = 1
    n_learner_population::Int = 20
    n_learner_children::Int = 20
    n_test_population::Int = 20
    n_test_children::Int = 20
    max_learner_archive_size::Int = 10
    n_dimensions::Int = 2
    init_range::Tuple{Float64, Float64} = (0.0, 0.1)
    domain::String = "CompareOnAll"
    use_delta::Bool = false
    delta::Float64 = 0.25
    n_mutations::Int = 2
    min_mutation::Float64 = -0.1
    max_mutation::Float64 = 0.1
    mutation_granularity::Float64 = 0.01
end

function get_ecosystem_creator(config::MaxSolveConfiguration)
    ecosystem_creator = MaxSolveEcosystemCreator(
        id = config.id,
        n_learner_population = config.n_learner_population,
        n_learner_children = config.n_learner_children,
        n_test_population = config.n_test_population,
        n_test_children = config.n_test_children,
        max_learner_archive_size = config.max_learner_archive_size,
    )
    return ecosystem_creator
end

dummy_species_creator() = BasicSpeciesCreator("A", 1, 1, 1, 1)


function create_reproducer(config::MaxSolveConfiguration, species_id::String)
    reproducer = BasicReproducer(
        id = species_id,
        genotype_creator = NumbersGameVectorGenotypeCreator(
            length = config.n_dimensions,
            init_range = config.init_range,
            mutation_granularity = config.mutation_granularity
        ),
        phenotype_creator = NumbersGamePhenotypeCreator(
            use_delta = config.use_delta, delta = config.delta
        ),
        individual_creator = BasicIndividualCreator(),
        species_creator = dummy_species_creator(),
        selector = IdentitySelector(),
        recombiner = CloneRecombiner(),
        mutator = NumbersGameVectorMutator(
            config.n_mutations, 
            config.min_mutation, 
            config.max_mutation, 
            config.mutation_granularity
        ),
    )
    return reproducer
end

function create_reproducers(config::MaxSolveConfiguration)
    learner_reproducer = create_reproducer(config, "L")
    test_reproducer = create_reproducer(config, "T")
    return [learner_reproducer, test_reproducer]
end

function create_simulator(config::MaxSolveConfiguration) 
    simulator = BasicSimulator(
        interactions = [
            BasicInteraction(
                id = "A",
                environment_creator = StatelessEnvironmentCreator(
                    domain = NumbersGameDomain(config.domain)
                ),
                species_ids = ["L", "T"],
            )
        ],
        matchmaker = AllVersusAllMatchMaker(),
        job_creator = SimpleJobCreator(n_workers = config.n_workers),
        performer = CachePerformer(n_workers = config.n_workers),
    )
    return simulator
end


function create_evaluators(::MaxSolveConfiguration)
    evaluator = NullEvaluator()
    return [evaluator]
end

function create_archivers(config::MaxSolveConfiguration)
    return Archiver[]
end

end