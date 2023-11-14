using Test

import Base: show

using HDF5
using CoEvo
using CoEvo.Names
using StableRNGs
using DataStructures: SortedDict

rng = StableRNG(42)

species_A = BasicSpecies(
    id = "A",
    population = [
        BasicIndividual(1, BasicVectorGenotype([1, 2, 3])),
        BasicIndividual(2, BasicVectorGenotype([4, 5, 6])),
    ], 
    children = [
        BasicIndividual(3, BasicVectorGenotype([7, 8, 9]), [1]),
        BasicIndividual(4, BasicVectorGenotype([10, 11, 12]), [2]),
    ]
)

species_B = BasicSpecies(
    id = "B",
    population = [
        BasicIndividual(5, BasicVectorGenotype([13, 14, 15])),
        BasicIndividual(6, BasicVectorGenotype([16, 17, 18])),
    ], 
    children = [
        BasicIndividual(7, BasicVectorGenotype([19, 20, 21]), [5]),
        BasicIndividual(8, BasicVectorGenotype([22, 23, 24]), [6]),
    ]
)

individual_outcomes = Dict(
    1 => Dict{Int, Float64}(5 => 1.0, 6 => 2.0, 7 => 3.0, 8 => 4.0),
    2 => Dict{Int, Float64}(5 => 5.0, 6 => 6.0, 7 => 7.0, 8 => 8.0),
    3 => Dict{Int, Float64}(5 => 9.0, 6 => 10.0, 7 => 11.0, 8 => 12.0),
    4 => Dict{Int, Float64}(5 => 13.0, 6 => 14.0, 7 => 15.0, 8 => 16.0),
    5 => Dict{Int, Float64}(1 => 17.0, 2 => 18.0, 3 => 19.0, 4 => 20.0),
    6 => Dict{Int, Float64}(1 => 21.0, 2 => 22.0, 3 => 23.0, 4 => 24.0),
    7 => Dict{Int, Float64}(1 => 25.0, 2 => 26.0, 3 => 27.0, 4 => 28.0),
    8 => Dict{Int, Float64}(1 => 29.0, 2 => 30.0, 3 => 31.0, 4 => 32.0),
)

evaluatator = ScalarFitnessEvaluator(maximum_fitness = 32.0 * 4)
evaluation = evaluate(evaluatator, rng, species_A, individual_outcomes)
evaluations = [
    evaluate(evaluatator, rng, species, individual_outcomes) 
    for species in [species_A, species_B]
]

state = BasicCoevolutionaryState(
    id = "test",
    random_number_generator = rng,
    trial = 1,
    generation = 1,
    last_reproduction_time = 0.0,
    evaluation_time = 0.0,
    individual_id_counter = BasicCounter(8),
    gene_id_counter = BasicCounter(24),
    species = [species_A, species_B],
    individual_outcomes = individual_outcomes,
    evaluations = evaluations,
    observations = [NullObservation()]
)




reporter = BasicReporter(metric = GlobalStateMetric(), save_interval = 1)
global_report = create_report(reporter, state)
#show(stdout, global_report)

reporter = BasicReporter(
    metric = AggregateSpeciesMetric(submetric = SumGenotypeMetric()),
    save_interval = 1
)
sum_report = create_report(reporter, state)
#show(stdout, sum_report)

reporter = BasicReporter(
    metric = AggregateSpeciesMetric(submetric = RawFitnessEvaluationMetric()),
    save_interval = 1
)
raw_report = create_report(reporter, state)
#show(stdout, raw_report)

reporter = BasicReporter(
    metric = AggregateSpeciesMetric(submetric = ScaledFitnessEvaluationMetric()),
    save_interval = 1
)
scaled_report = create_report(reporter, state)
#show(stdout, scaled_report)

reporter = BasicReporter(
    metric = SnapshotSpeciesMetric(),
    save_interval = 1,
    print_interval = 0,
)

snapshot_report = create_report(reporter, state)

reports = [global_report, sum_report, raw_report, scaled_report, snapshot_report]


# The rest of the functions remain the same.
#print_reports(reports, BasicArchiver())
if isfile("archive.h5")
    rm("archive.h5")
end
file = h5open("archive.h5", "w")
close(file)
archive!(BasicArchiver(), reports)

