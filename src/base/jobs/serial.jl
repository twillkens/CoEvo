export SerialJob, SerialJobConfig

struct SerialJob <: Job
    recipes::Set{Recipe}
    phenodict::Dict{String, Phenotype}
end

struct SerialJobConfig <: JobConfig end

function(cfg::SerialJobConfig)(orders::Set{<:Order}, pops::Set{<:Population})
    recipes = Set{Recipe}(orders, pops)
    genodict = Dict{String, Genotype}(pops)
    phenodict = Dict{String, Phenotype}(recipes, genodict)
    SerialJob(recipes, phenodict)
end

function Set{Mix}(job::SerialJob)
    Set{Mix}(job.recipes, job.phenodict)
end

function Set{Outcome}(job::SerialJob)
    mixes = Set{Mix}(job.recipes, job.phenodict)
    Set([(mix)() for mix in mixes])
end