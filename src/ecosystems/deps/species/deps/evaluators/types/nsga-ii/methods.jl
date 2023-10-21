module NSGAIIMethods

export NSGAIIRecord, nsga_sort!, nsga_tournament, Max, Min, Sense
export dominates, fast_non_dominated_sort!, crowding_distance_assignment!

using Random
using DataStructures: SortedDict

abstract type Sense end

struct Max <: Sense end
struct Min <: Sense end

Base.@kwdef mutable struct NSGAIIRecord
    id::Int = 0
    fitness::Float64 = 0
    disco_fitness::Float64 = 0
    tests::Vector{Float64} = Float64[]
    rank::Int = 0
    crowding::Float64 = 0.0
    dom_count::Int = 0
    dom_list::Vector{Int} = Int[]
end

function dominates(::Max, a::NSGAIIRecord, b::NSGAIIRecord)
    res = false
    for i in eachindex(a.tests)
        @inbounds a.tests[i] < b.tests[i] && return false
        @inbounds a.tests[i] > b.tests[i] && (res = true)
    end
    res
end

function dominates(::Min, a::NSGAIIRecord, b::NSGAIIRecord)
    res = false
    for i in eachindex(a.tests)
        @inbounds a.tests[i] > b.tests[i] && return false
        @inbounds a.tests[i] < b.tests[i] && (res = true)
    end
    res
end

function fast_non_dominated_sort!(individuals::Vector{<:NSGAIIRecord}, sense::Sense)
    n = length(individuals)

    for p in individuals
        empty!(p.dom_list)
        p.dom_count = 0
        p.rank = 0
    end

    @inbounds for i in 1:n
        for j in i+1:n
            if dominates(sense, individuals[i], individuals[j])
                push!(individuals[i].dom_list, j)
                individuals[j].dom_count += 1
            elseif dominates(sense, individuals[j], individuals[i])
                push!(individuals[j].dom_list, i)
                individuals[i].dom_count += 1
            end
        end
        if individuals[i].dom_count == 0
            individuals[i].rank = 1
        end
    end

    k = UInt16(2)
    @inbounds while any(==(k-one(UInt16)), (p.rank for p in individuals)) #ugly workaround for #15276
        for p in individuals 
            if p.rank == k-one(UInt16)
                for q in p.dom_list
                    individuals[q].dom_count -= one(UInt16)
                    if individuals[q].dom_count == zero(UInt16)
                        individuals[q].rank = k
                    end
                end
            end
        end
        k += one(UInt16)
    end
    nothing
end

function crowding_distance_assignment!(
    individuals::Vector{<:NSGAIIRecord},
    function_minimums::Union{Nothing, Vector{Float64}} = nothing,
    function_maximums::Union{Nothing, Vector{Float64}} = nothing
)
    @inbounds for j = 1:length(first(individuals).tests) # Foreach objective
        let j = j #https://github.com/JuliaLang/julia/issues/15276
            sort!(individuals, by = x -> x.tests[j]) #sort by the objective value
        end
        individuals[1].crowding = individuals[end].crowding = Inf #Assign infinite value to extremas
        if individuals[1].tests[j] != individuals[end].tests[j]
            for i = 2:length(individuals) - 1
                greater_neighbor_value = individuals[i + 1].tests[j] 
                lesser_neighbor_value = individuals[i - 1].tests[j]
                minimum_value = function_minimums === nothing ? 
                    individuals[1].tests[j] :
                    function_minimums[j]
                maximum_value = function_maximums === nothing ? 
                    individuals[end].tests[j] :
                    function_maximums[j]
                crowding = (greater_neighbor_value - lesser_neighbor_value) / 
                           (maximum_value - minimum_value)
                individuals[i].crowding += crowding
            end
        end
    end
end

function nsga_sort!(
    individuals::Vector{<:NSGAIIRecord}, 
    sense::Sense = Max(), 
    function_minimums::Union{Nothing, Vector{Float64}} = nothing,
    function_maximums::Union{Nothing, Vector{Float64}} = nothing
)
    fast_non_dominated_sort!(individuals, sense)
    sort!(individuals, by = ind -> ind.rank, alg = Base.Sort.QuickSort)
    fronts = SortedDict{Int, Vector{<:NSGAIIRecord}}()
    for ind in individuals 
        if haskey(fronts, ind.rank)
            a = fronts[ind.rank]
            push!(a, ind)
        else
            fronts[ind.rank] = [ind]
        end
    end
    sorted_indivs = NSGAIIRecord[]
    for front_indivs in values(fronts)
        crowding_distance_assignment!(front_indivs, function_minimums, function_maximums)
        sort!(
            front_indivs, 
            by = ind -> ind.crowding,
            rev=true, alg=Base.Sort.QuickSort
        )
        append!(sorted_indivs, front_indivs)
    end
    sorted_indivs
end


function nsga_tournament(rng::AbstractRNG, parents::Array{<:NSGAIIRecord}, tourn_size::Int64) 
    function get_winner(d1::NSGAIIRecord, d2::NSGAIIRecord)
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


#Base.@kwdef struct NSGASelector <: Selector
#    μ::Int = 50
#    tsize::Int = 3
#    sense::Sense = Max()
#end

#function(s::NSGASelector)(rng::AbstractRNG, population::Vector{<:Individual}, evals::Dict{Int, NSGAIIRecord})
#    population = nsga!(population, )
#    [nsga_tournament(rng, population, c.tsize) for _ in 1:s.μ]
#end

end