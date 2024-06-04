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
struct FSMArchiver <: Archiver 
    data::DataFrame
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
    return FSMArchiver(data)
end

function archive!(archiver::FSMArchiver, state::State)
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
