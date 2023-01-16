
Base.@kwdef struct NSGAiiSelector <: Selector
    n_elite::Int
    n_singles::Int
    n_couples::Int
end

function(s::NSGAiiSelector)(pop::ParetoPop, outcomes::Set{<:Outcome})
    n_elite, n_singles, n_couples = s.n_elite, s.n_singles, s.n_couples
    if n_elite + n_singles + n_couples != length(pop.genos)
        error("Invalid RouletteSelector configuration")
    end
    genos, fitness = get_scores(pop, outcomes)
    elites = [genos[i] for i in 1:n_elite]
    singles = [genos[i] for i in roulette(fitness, n_singles; rng = rng)]
    idxs = roulette(fitness, n_couples * 2; rng = rng)
    couples = [(genos[idxs[i]], genos[idxs[i + 1]]) for i in 1:2:length(idxs)]
    GenoSelections(elites, singles, couples)
end




mutable struct ParetoRecord
    key::String
    outcomes::SortedDict{String, Float64}
    X::Vector{Float64}
    rank::UInt16
    crowding::Float64
    dom_count::UInt16
    dom_list::Vector{UInt16}    
end

abstract type Sense end
struct Max <: Sense end
struct Min <: Sense end

function dominates(::Max, a::ParetoRecord, b::ParetoRecord)
    res = false
    for i in eachindex(a.X)
        @inbounds a.X[i] < b.X[i] && return false
        @inbounds a.X[i] > b.X[i] && (res = true)
    end
    res
end

function dominates(::Min, a::DiscoRecord, b::DiscoRecord)
    res = false
    for i in eachindex(a.X)
        @inbounds a.X[i] > b.X[i] && return false
        @inbounds a.X[i] < b.X[i] && (res = true)
    end
    res
end


function fast_non_dominated_sort!(indivs::Vector{ParetoRecord}, sense::Sense)
    n = length(indivs)

    for p in indivs
        empty!(p.dom_list)
        p.dom_count = 0
        p.rank = 0
    end

    @inbounds for i in 1:n
        for j in (i + 1):n
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
            if p.rank == k - one(UInt16)
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


function crowding_distance_assignment!(indivs::Vector{DiscoRecord})
    for ind in indivs
        ind.crowding = 0.
    end
    @inbounds for j = 1:length(first(indivs).X) # Foreach objective
        let j = j #https://github.com/JuliaLang/julia/issues/15276
            sort!(indivs, by = x -> x.X[j]) #sort by the objective value
        end
        indivs[1].crowding = indivs[end].crowding = Inf #Assign infinite value to extremas
        if indivs[1].X[j] != indivs[end].X[j]
            for i = 2:length(indivs)-1
                numerator = (indivs[i+1].X[j] - indivs[i-1].X[j])
                denominator = (indivs[end].X[j] - indivs[1].X[j]) 
                indivs[i].crowding +=  numerator / denominator 
            end
        end
    end
end

function nsga!(indivs::Vector{GNARLIndividual}, sense::Sense)
    discos = map(ind -> ind.disco, indivs)
    fast_non_dominated_sort!(discos, sense)
    sort!(indivs, by=ind -> ind.disco.rank, alg=Base.Sort.QuickSort)
    fronts = SortedDict{UInt16, Vector{GNARLIndividual}}()
    for ind in indivs 
        if haskey(fronts, ind.disco.rank)
            a = fronts[ind.disco.rank]
            push!(a, ind)
        else
            fronts[ind.disco.rank] = [ind]
        end
    end
    sorted_indivs = Vector{GNARLIndividual}()
    for front in values(fronts)
        discos = map(ind -> ind.disco, front)
        crowding_distance_assignment!(discos)
        sort!(front, by=ind -> ind.disco.crowding,
              rev=true, alg=Base.Sort.QuickSort)
        append!(sorted_indivs, front)
    end
    sorted_indivs
end

function nsga