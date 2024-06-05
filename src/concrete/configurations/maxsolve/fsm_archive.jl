export FSMArchiver

using DataFrames
using CSV
using ....Abstract
using ....Interfaces
using Serialization
#
#struct FSMArchiver <: Archiver 
#end
#
#function archive!(archiver::FSMArchiver, state::State)
#    #all_data = DataFrame()
#    learner_genotypes = [minimize(learner.genotype) for learner in state.ecosystem.learner_population]
#    genotype_sizes = [length(genotype.ones) + length(genotype.zeros) for genotype in learner_genotypes]
#    println("Genotype sizes: ", genotype_sizes)
#end
#

struct ModesPruner{E <: Ecosystem, I <: Individual}
    checkpoint_interval::Int
    previous_ecosystem::E
    previous_pruned::Set{I}
    all_pruned::Set{I}
end

function ModesPruner(state::State)
    I = typeof(state.ecosystem.learner_population[1])
    return ModesPruner(200, state.ecosystem, Set{I}(), Set{I}())
end

function update!(pruner::ModesPruner, state::State)
    pruner.previous_ecosystem = deepcopy(state.ecosystem)
    pruner.previous_pruned = pruner.all_pruned
    pruner.all_pruned = Set{typeof(state.ecosystem.learner_population[1])}()
end

mutable struct FSMArchiver <: Archiver 
    data::DataFrame
    pruner::Any
end

function FSMArchiver(configuration::MaxSolveConfiguration)
    save_file = get_save_file(configuration)
    if isfile(save_file)
        data = CSV.read(save_file, DataFrame)
    else
        data = DataFrame(
            trial = Int[], 
            algorithm = String[],
            generation = Int[], 
            fitness = Float64[], 
            score = Float64[], 
            seed = Int[]
        )
    end
    return FSMArchiver(data, nothing)
end

function archive!(archiver::FSMArchiver, state::State)
    #if state.generation == 1
    #    archiver.pruner = ModesPruner(state)
    #else
    #    update!(archiver.pruner, state)
    #end
    elite_fitness = -1
    elite = nothing
    for learner in [state.ecosystem.learner_population ; state.ecosystem.learner_children]
        p = state.ecosystem.payoff_matrix
        if state.configuration.learner_algorithm == "control"
            fitness = rand(state.rng)
        else
            fitness = sum(p[learner.id, :])
        end
        if fitness > elite_fitness
            elite_fitness = fitness
            elite = learner
        end
    end
    learner_genotype = minimize(elite.genotype)
    score = length(learner_genotype.ones) + length(learner_genotype.zeros)
    info = (
        trial = state.configuration.id, 
        algorithm = state.configuration.test_algorithm,
        generation = state.generation, 
        fitness = elite_fitness,
        score = score,
        seed = state.configuration.seed
    )
    push!(archiver.data, info)
    CSV.write(get_save_file(state.configuration), archiver.data)
end
