module Utilities

export Counter, next!, divvy, Max, Min

using ..CoEvo: Sense

struct Max <: Sense end
struct Min <: Sense end

mutable struct Counter
    curr::Int
end
Counter() = Counter(1)

function next!(c::Counter)
    val = c.curr
    c.curr += 1
    val
end

function next!(c::Counter, n::Int)
    [next!(c) for _ in 1:n]
end

function divvy(items::Vector{T}, njobs::Int) where T
    n = length(items)
    # Base size for each job
    base_size = div(n, njobs)
    # Number of jobs that will take an extra item
    extras = n % njobs
    partitions = Vector{Vector{T}}()
    start_idx = 1
    for _ in 1:njobs
        end_idx = start_idx + base_size - 1
        if extras > 0
            end_idx += 1
            extras -= 1
        end
        push!(partitions, items[start_idx:end_idx])
        start_idx = end_idx + 1
    end
    return partitions
end

end