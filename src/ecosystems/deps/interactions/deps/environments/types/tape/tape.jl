module Tape

struct TapeEnvironment{D <: Domain} <: Environment 
    domain::D
    indiv_ids::Vector{Int}
    phenotypes::Vector{Phenotype}
    tape1::Vector{Float64}
    tape2::Vector{Float64}
end

struct TapeEnvironmentCreator{D <: Domain} <: EnvironmentCreator
    domain::D
end

end