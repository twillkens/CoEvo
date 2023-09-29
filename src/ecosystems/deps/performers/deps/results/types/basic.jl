module Basic

export BasicResult

struct BasicResult{OBS <: Observation} <: Result
    domain_id::String
    indiv_ids::Vector{Int}
    outcome_set::Vector{Float64}
    observations::Vector{OBS}
end

end