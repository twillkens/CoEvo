using Test

"""
    CoEvo Test Suite

This test suite focuses on validating and verifying the functionality of the `CoEvo` module.
The `CoEvo` module provides tools and structures for co-evolutionary simulations.
"""

@testset "SymbolicRegression" begin
println("Starting tests for SymbolicRegression...")

#include("../src/CoEvo.jl")
#using .CoEvo
using .Metrics.Concrete.Common: AbsoluteError

using .Genotypes.GeneticPrograms.Utilities: Utilities as GPUtilities
using .GPUtilities: protected_division, Terminal, FuncAlias, protected_sine, if_less_then_else
@testset "evolve!" begin

function sym_regress_eco_creator(;
    id::String = "Symbolic Regression",
    trial::Int = 1,
    random_number_generator::AbstractRNG = StableRNG(42),
    n_population::Int = 100,
    species_id1::String = "Subjects",
    species_id2::String = "Tests",
    interaction_id::String = "SymbolicRegression",
    n_elite::Int = 10
)
    ecosystem_creator = BasicEcosystemCreator(
        id = id,
        trial = trial,
        random_number_generator = random_number_generator,
        species_creators = Dict(
            species_id1 => BasicSpeciesCreator(
                id = species_id1,
                n_population = n_population,
                genotype_creator = GeneticProgramGenotypeCreator(),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = ScalarFitnessEvaluator(maximize = false),
                replacer = GenerationalReplacer(n_elite = n_elite),
                selector = FitnessProportionateSelector(n_parents = n_population),
                recombiner = CloneRecombiner(),
                mutators = [GeneticProgramMutator(
                    functions = Dict{FuncAlias, Int}([
                        (+, 2),
                        (-, 2),
                        (*, 2),
                        (protected_division, 2),
                    ]),
                )],
            ),
            species_id2 => BasicSpeciesCreator(
                id = species_id2,
                n_population = 100,
                genotype_creator = ScalarRangeGenotypeCreator(
                    start_value = -5.0,
                    stop_value = 5.0,
                ),
                phenotype_creator = DefaultPhenotypeCreator(),
                evaluator = NullEvaluator(),
                replacer = IdentityReplacer(),
                selector = IdentitySelector(),
                recombiner = IdentityRecombiner(),
                mutators = [IdentityMutator()],
            ),
        ),
        job_creator = BasicJobCreator(
            n_workers = 1,
            interactions = Dict(
                interaction_id => BasicInteraction(
                    id = interaction_id,
                    environment_creator = StatelessEnvironmentCreator(
                        SymbolicRegressionDomain(
                            outcome_metric = AbsoluteError(),
                            target_function = x -> x^2 + x + π
                        )),
                    species_ids = [species_id1, species_id2],
                    matchmaker = AllvsAllMatchMaker(type = :plus),
                ),
            ),
        ),
        performer = BasicPerformer(n_workers = 1),
        reporters = Reporter[
            # BasicReporter(metric = AbsoluteError()),
        ],
        archiver = BasicArchiver(),
        runtime_reporter = RuntimeReporter(print_interval = 0),
    )
    return ecosystem_creator

end

ecosystem_creator = sym_regress_eco_creator(n_population = 100)
eco = evolve!(ecosystem_creator, n_generations=10)
@test length(eco.species) == 2

end

println("Finished tests for SymbolicRegression.")
end