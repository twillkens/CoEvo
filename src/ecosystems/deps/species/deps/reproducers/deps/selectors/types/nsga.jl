module NSGA

using Random
using ...CoEvo: Sense
using ...CoEvo.Utilities: Max, Min
using ..Evaluations: DiscoEval

function dominates(::Max, a::DiscoEval, b::DiscoEval)
    res = false
    for i in eachindex(a.derived_tests)
        @inbounds a.derived_tests[i] < b.derived_tests[i] && return false
        @inbounds a.derived_tests[i] > b.derived_tests[i] && (res = true)
    end
    res
end

function dominates(::Min, a::DiscoEval, b::DiscoEval)
    res = false
    for i in eachindex(a.derived_tests)
        @inbounds a.derived_tests[i] > b.derived_tests[i] && return false
        @inbounds a.derived_tests[i] < b.derived_tests[i] && (res = true)
    end
    res
end

function fast_non_dominated_sort!(indivs::Vector{<:DiscoEval}, sense::Sense)
    n = length(indivs)

    for p in indivs
        empty!(p.dom_list)
        p.dom_count = 0
        p.rank = 0
    end

    @inbounds for i in 1:n
        for j in i+1:n
            if dominates(sense, indivs[i], indivs[j])
                push!(indivs[i].dom_list, j)
                indivs[j].dom_count += 1
            elseif dominates(sense, indivs[j], indivs[i])
                push!(indivs[j].dom_list, i)
                indivs[i].dom_count += 1
            end
        end
        if indivs[i].dom_count == 0
            indivs[i].rank = 1
        end
    end

    k = UInt16(2)
    @inbounds while any(==(k-one(UInt16)), (p.rank for p in indivs)) #ugly workaround for #15276
        for p in indivs 
            if p.rank == k-one(UInt16)
                for q in p.dom_list
                    indivs[q].dom_count -= one(UInt16)
                    if indivs[q].dom_count == zero(UInt16)
                        indivs[q].rank = k
                    end
                end
            end
        end
        k += one(UInt16)
    end
    nothing
end

function crowding_distance_assignment!(indivs::Vector{<:DiscoEval})
    for ind in indivs
        ind.crowding = 0.
    end
    @inbounds for j = 1:length(first(indivs).derived_tests) # Foreach objective
        let j = j #https://github.com/JuliaLang/julia/issues/15276
            sort!(indivs, by = x -> x.derived_tests[j]) #sort by the objective value
        end
        indivs[1].crowding = indivs[end].crowding = Inf #Assign infinite value to extremas
        if indivs[1].derived_tests[j] != indivs[end].derived_tests[j]
            for i = 2:length(indivs)-1
                indivs[i].crowding += (indivs[i+1].derived_tests[j] - indivs[i-1].derived_tests[j]) / (indivs[end].derived_tests[j] - indivs[1].derived_tests[j])
            end
        end
    end
end

function nsga!(indivs::Vector{<:DiscoEval}, sense::Sense = Max())
    fast_non_dominated_sort!(indivs, sense)
    sort!(indivs, by = ind -> ind.rank, alg = Base.Sort.QuickSort)
    fronts = SortedDict{Int, Vector{<:DiscoEval}}()
    for ind in indivs 
        if haskey(fronts, ind.rank)
            a = fronts[ind.rank]
            push!(a, ind)
        else
            fronts[ind.rank] = [ind]
        end
    end
    sorted_indivs = DiscoEval[]
    for front_indivs in values(fronts)
        crowding_distance_assignment!(front_indivs)
        sort!(
            front_indivs, 
            by = ind -> ind.crowding,
            rev=true, alg=Base.Sort.QuickSort
        )
        append!(sorted_indivs, front)
    end
    sorted_indivs
end


function nsga_tournament(rng::AbstractRNG, parents::Array{<:DiscoEval}, tourn_size::Int64) 
    function get_winner(d1::DiscoEval, d2::DiscoEval)
        if d1.rank < d2.rank
            return ind1
        elseif d2.rank < d1.rank
            return ind2
        else
            if d1.crowding > d2.crowding
                return ind1
            elseif d2.crowding > d1.crowding
                return ind2
            else
                return rand(rng, (ind1, ind2))
            end
        end
    end
    contenders = rand(rng, parents, tourn_size)
    reduce(get_winner, contenders)
end


Base.@kwdef struct NSGASelector <: Selector
    μ::Int = 50
    tsize::Int = 3
    sense::Sense = Max()
end

function(s::NSGASelector)(rng::AbstractRNG, pop::Vector{<:Individual}, evals::Dict{Int, DiscoEval})
    pop = nsga!(pop, )
    [nsga_tournament(rng, pop, c.tsize) for _ in 1:s.μ]
end

end