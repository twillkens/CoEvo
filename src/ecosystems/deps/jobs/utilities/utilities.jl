"""
    Utilities

The `Utilities` module provides a set of utility functions that aid in common
computation tasks. 

# Functions
- `divvy`: Partitions a vector into approximately equal parts based on the 
  number of specified jobs. Useful for workload distribution tasks.
"""
module Utilities

# Exported Functions
export divvy

"""
    divvy(items::Vector{T}, njobs::Int) where T

Partition the `items` vector into approximately equal-sized chunks based on the 
specified number of jobs (`njobs`). If the items cannot be evenly divided, 
some partitions might contain an extra item.

# Arguments
- `items::Vector{T}`: A vector of items to be partitioned.
- `njobs::Int`: The number of partitions or jobs required.

# Returns
- A vector of vectors, where each inner vector represents a partition of the items.
"""
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
