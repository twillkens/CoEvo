export ParallelJob, ParallelJobsConfig


struct ParallelJob{R <: Recipe, I <: Ingredient, G <: Genotype} <: Job
    recipes::Set{R}
    genodict::Dict{I, G}
end

