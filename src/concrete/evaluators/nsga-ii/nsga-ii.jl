module NSGAII

export NSGAIIRecord, nsga_sort!, nsga_tournament
export dominates, fast_non_dominated_sort!, crowding_distance_assignment!
export is_nondominated

using ....Abstract
using ...Criteria: Maximize, Minimize
using Random: AbstractRNG, rand
using DataStructures: SortedDict
using StableRNGs: StableRNG
using StatsBase: mean
using LinearAlgebra: dot

Base.@kwdef mutable struct NSGAIIRecord <: Record
    id::Int = 0
    other_id::Int = 0
    outcomes::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function is_nondominated(a::Vector{<:Real}, b::Vector{<:Real})
    for i in eachindex(a)
        @inbounds a[i] > b[i] && return true
    end
    return false
end

function dominates(::Maximize, a::Vector{<:Real}, b::Vector{<:Real})
    res = false
    for i in eachindex(a)
        @inbounds a[i] < b[i] && return false
        @inbounds a[i] > b[i] && (res = true)
    end
    res
end

function dominates(::Maximize, a::Record, b::Record)
    res = false
    for i in eachindex(a.outcomes)
        @inbounds a.outcomes[i] < b.outcomes[i] && return false
        @inbounds a.outcomes[i] > b.outcomes[i] && (res = true)
    end
    res
end

function dominates(::Minimize, a::Record, b::Record)
    res = false
    for i in eachindex(a.outcomes)
        @inbounds a.outcomes[i] > b.outcomes[i] && return false
        @inbounds a.outcomes[i] < b.outcomes[i] && (res = true)
    end
    res
end

function fast_non_dominated_sort!(records::Vector{<:Record}, criterion::Criterion)
    n = length(records)

    for p in records
        empty!(p.dom_list)
        p.dom_count = 0
        p.rank = 0
    end

    @inbounds for i in 1:n
        for j in i+1:n
            if dominates(criterion, records[i], records[j])
                push!(records[i].dom_list, j)
                records[j].dom_count += 1
            elseif dominates(criterion, records[j], records[i])
                push!(records[j].dom_list, i)
                records[i].dom_count += 1
            end
        end
        if records[i].dom_count == 0
            records[i].rank = 1
        end
    end

    k = UInt16(2)
    @inbounds while any(==(k - one(UInt16)), (p.rank for p in records))
        for p in records 
            if p.rank == k - one(UInt16)
                for q in p.dom_list
                    records[q].dom_count -= one(UInt16)
                    if records[q].dom_count == zero(UInt16)
                        records[q].rank = k
                    end
                end
            end
        end
        k += one(UInt16)
    end
    nothing
end

function crowding_distance_assignment!(
    records::Vector{<:Record},
    function_minimums::Union{Nothing, Vector{Float64}} = nothing,
    function_maximums::Union{Nothing, Vector{Float64}} = nothing
)
    @inbounds for j = 1:length(first(records).outcomes)
        let j = j 
            sort!(records, by = x -> x.outcomes[j]) 
        end
        #TODO check and test this
        if records[1].outcomes[j] == records[end].outcomes[j]
            continue
        end
        records[1].crowding = records[end].crowding = Inf 
        for i = 2:length(records) - 1
            greater_neighbor_value = records[i + 1].outcomes[j] 
            lesser_neighbor_value = records[i - 1].outcomes[j]
            minimum_value = function_minimums === nothing ? 
                records[1].outcomes[j] :
                function_minimums[j]
            maximum_value = function_maximums === nothing ? 
                records[end].outcomes[j] :
                function_maximums[j]
            crowding = (greater_neighbor_value - lesser_neighbor_value) / 
                        (maximum_value - minimum_value)
            records[i].crowding += crowding
        end
    end
end

function nsga_sort!(
    records::Vector{R}, 
    criterion::Criterion = Maximize(),
    function_minimums::Union{Nothing, Vector{Float64}} = nothing,
    function_maximums::Union{Nothing, Vector{Float64}} = nothing
) where {R <: Record}
    fast_non_dominated_sort!(records, criterion)
    sort!(records, by = ind -> ind.rank, alg = Base.Sort.QuickSort)
    fronts = SortedDict{Int, Vector{R}}()
    for ind in records 
        if haskey(fronts, ind.rank)
            a = fronts[ind.rank]
            push!(a, ind)
        else
            fronts[ind.rank] = [ind]
        end
    end
    sorted_indivs = R[]
    for front_indivs in values(fronts)
        crowding_distance_assignment!(front_indivs, function_minimums, function_maximums)
        sort!(front_indivs, by = ind -> ind.crowding, rev = true, alg = Base.Sort.QuickSort)
        append!(sorted_indivs, front_indivs)
    end
    sorted_indivs = [r for r in sorted_indivs]
    return sorted_indivs
end

function nsga_tournament(
    rng::AbstractRNG, parents::Vector{<:Record}, tourn_size::Int64
) 
    function get_winner(d1::Record, d2::Record)
        if d1.rank < d2.rank
            return d1
        elseif d2.rank < d1.rank
            return d2
        else
            if d1.crowding > d2.crowding
                return d1
            elseif d2.crowding > d1.crowding
                return d2
            else
                return rand(rng, (d1, d2))
            end
        end
    end
    contenders = rand(rng, parents, tourn_size)
    winner = reduce(get_winner, contenders)
    return winner
end


end