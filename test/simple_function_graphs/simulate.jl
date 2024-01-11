
using Test
using Base: @kwdef
using CoEvo
using Random  
using StableRNGs: StableRNG
using CoEvo.Names
using CoEvo.Genotypes.SimpleFunctionGraphs
using CoEvo.Mutators.SimpleFunctionGraphs
#using CoEvo.Mutators.FunctionGraphs: add_function as fg_add_function, remove_function as fg_remove_function
using CoEvo.Phenotypes.FunctionGraphs.Complete
#using CoEvo.Phenotypes.FunctionGraphs.Basic
using ProgressBars

function run_simulation(
    genotype_1::SimpleFunctionGraphGenotype, 
    genotype_2::SimpleFunctionGraphGenotype, 
    episode_length::Int,
)
    domain = PredictionGameDomain("PredatorPrey")
    phenotype_creator = CompleteFunctionGraphPhenotypeCreator()
    phenotype_1 = create_phenotype(phenotype_creator, genotype_1, 1)
    phenotype_2 = create_phenotype(phenotype_creator, genotype_2, 2)
    environment = create_environment(
        ContinuousPredictionGameEnvironmentCreator(
        domain=domain, episode_length=episode_length), 
        Phenotype[phenotype_1, phenotype_2]
    )

    for i in 1:episode_length
        step!(environment)
    end
end

Base.@kwdef mutable struct DummyState <: State
    rng::StableRNG
    individual_id_counter::BasicCounter
    gene_id_counter::BasicCounter
end

state = DummyState(StableRNG(42), BasicCounter(2), BasicCounter(7))

    
        
rng = StableRNG(42)
genotype_creator = SimpleFunctionGraphGenotypeCreator(2, 1, 1)
genotype_1, genotype_2 = create_genotypes(genotype_creator, rng, BasicCounter(1), 2)

static_mutator = SimpleFunctionGraphMutator(
    max_mutations = 10,
    n_mutations_decay_rate = 0.5,
    recurrent_edge_probability = 0.5,
    mutation_weights = Dict(
        :add_node! => 0.0,
        :remove_node! => 0.0,
        :mutate_node! => 1.0,
        :mutate_edge! => 1.0,
    ),
    noise_std = 1000,
    validate_genotypes = true,
    #function_set = [:MODULO, :DIVIDE, :MULTIPLY, :ADD, :EXP, :NATURAL_LOG]
) 
add_mutator = SimpleFunctionGraphMutator(
    max_mutations = 1,
    n_mutations_decay_rate = 0.5,
    recurrent_edge_probability = 0.5,
    mutation_weights = Dict(
        :add_node! => 1.0,
        :remove_node! => 0.0,
        :mutate_node! => 0.0,
        :mutate_edge! => 0.0,
    ),
    noise_std = 1000,
    validate_genotypes = true,
    #function_set = [:MODULO, :DIVIDE, :MULTIPLY, :ADD, :EXP, :NATURAL_LOG]
) 

for i in ProgressBar(1:500)
    for j in ProgressBar(1:1000)
        try 
            run_simulation(genotype_1, genotype_2, 512)
        catch
            println("genotype_1 = $genotype_1")
            println("genotype_2 = $genotype_2")
            throw(ErrorException("Error in run_simulation"))
        end
        mutate!(static_mutator, genotype_1, state)
        mutate!(static_mutator, genotype_2, state)
    end
    mutate!(add_mutator, genotype_1, state)
    mutate!(add_mutator, genotype_2, state)
end
