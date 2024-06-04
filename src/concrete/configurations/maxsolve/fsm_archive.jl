export FSMArchiver

using DataFrames
using CSV
using ....Abstract
using Serialization

struct FSMArchiver <: Archiver 
end

function archive!(archiver::FSMArchiver, state::State)
    #all_data = DataFrame()
    learner_genotypes = [minimize(learner.genotype) for learner in state.ecosystem.learner_population]
    genotype_sizes = [length(genotype.ones) + length(genotype.zeros) for genotype in learner_genotypes]
    println("Genotype sizes: ", genotype_sizes)
end
