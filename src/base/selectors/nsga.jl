export NSGAiiRecord, NSGAiiSelector, nsga, Max, Min, fast_non_dominated_sort!

abstract type Sense end
struct Max <: Sense end
struct Min <: Sense end

Base.@kwdef struct NSGAiiSelector <: Selector
    n_elite::Int
    n_singles::Int
    n_couples::Int
    localminmax::Bool
    fmins::Vector{Float64}
    fmaxes::Vector{Float64}
    sense::Sense
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


mutable struct NSGAiiRecord{T <: Genotype} 
    key::String
    geno::T
    outcomes::SortedDict{String, Float64}
    X::Vector{Float64}
    rank::UInt16
    crowding::Float64
    dom_count::UInt16
    dom_list::Vector{UInt16}    
end

function NSGAiiRecord(geno::Genotype, outcomes::SortedDict{String, Float64})
    NSGAiiRecord(key, geno, outcomes, collect(values(outcomes)),
                  UInt16(0), -1.0, UInt16(0), Vector{UInt16}())
end

function NSGAiiRecord(geno::Genotype, X::Vector{Float64})
    NSGAiiRecord(geno.key, geno, SortedDict{String, Float64}(), X,
                  UInt16(0), -1.0, UInt16(0), Vector{UInt16}())
end

function dominates(::Max, a::NSGAiiRecord, b::NSGAiiRecord)
    res = false
    for i in eachindex(a.X)
        @inbounds a.X[i] < b.X[i] && return false
        @inbounds a.X[i] > b.X[i] && (res = true)
    end
    res
end

function dominates(::Min, a::NSGAiiRecord, b::NSGAiiRecord)
    res = false
    for i in eachindex(a.X)
        @inbounds a.X[i] > b.X[i] && return false
        @inbounds a.X[i] < b.X[i] && (res = true)
    end
    res
end


function fast_non_dominated_sort!(recs::Vector{NSGAiiRecord{T}}, sense::Sense) where T
    n = length(recs)

    for p in recs
        empty!(p.dom_list)
        p.dom_count = 0
        p.rank = 0
    end

    @inbounds for i in 1:n
        for j in (i + 1):n
            if dominates(sense, recs[i], recs[j])
                push!(recs[i].dom_list, j)
                recs[j].dom_count += 1
            elseif dominates(sense, recs[j], recs[i])
                push!(recs[j].dom_list, i)
                recs[i].dom_count += 1
            end
        end
        if recs[i].dom_count == 0
            recs[i].rank = 1
        end
    end

    k = UInt16(2)
    @inbounds while any(==(k-one(UInt16)), (p.rank for p in recs)) #ugly workaround for #15276
        for p in recs 
            if p.rank == k - one(UInt16)
                for q in p.dom_list
                    recs[q].dom_count -= one(UInt16)
                    if recs[q].dom_count == zero(UInt16)
                        recs[q].rank = k
                    end
                end
            end
        end
        k += one(UInt16)
    end
    sort!(recs, by = r -> r.rank, alg = Base.Sort.QuickSort)
    nothing
end


function crowding_distance_assignment!(selector::NSGAiiSelector, recs::Vector{NSGAiiRecord})
        
    for rec in recs
        rec.crowding = 0.0
    end
    @inbounds for j = 1:length(first(recs).X) # Foreach objective
        let j = j #https://github.com/JuliaLang/julia/issues/15276
            sort!(recs, by = x -> x.X[j]) #sort by the objective value
        end
        recs[1].crowding = recs[end].crowding = Inf #Assign infinite value to extremas
        if recs[1].X[j] != recs[end].X[j]
            for i = 2:length(recs)-1
                numerator = (recs[i+1].X[j] - recs[i-1].X[j])
                if selector.localminmax
                    denominator = (recs[end].X[j] - recs[1].X[j]) 
                else
                    denominator = (selector.fmaxes[j] - selector.fmins[j]) 
                end
                recs[i].crowding +=  numerator / denominator 
            end
        end
    end
    sort(recs, by = rec -> rec.crowding, rev = true, alg = Base.Sort.QuickSort)
    recs
end

# function nsga!(recs::Vector{GNARLIndividual}, sense::Sense)
#     discos = map(rec -> rec.disco, recs)
#     fast_non_dominated_sort!(discos, sense)
#     sort!(recs, by=rec -> rec.disco.rank, alg=Base.Sort.QuickSort)
#     fronts = SortedDict{UInt16, Vector{GNARLIndividual}}()
#     for rec in recs 
#         if haskey(fronts, rec.disco.rank)
#             a = fronts[rec.disco.rank]
#             push!(a, rec)
#         else
#             fronts[rec.disco.rank] = [rec]
#         end
#     end
#     sorted_recs = Vector{GNARLIndividual}()
#     for front in values(fronts)
#         discos = map(rec -> rec.disco, front)
#         crowding_distance_assignment!(discos)
#         sort!(front, by=rec -> rec.disco.crowding,
#               rev=true, alg=Base.Sort.QuickSort)
#         append!(sorted_recs, front)
#     end
#     sorted_recs
# end


function nsga(s::NSGAiiSelector, records::Vector{NSGAiiRecord{T}}) where T
    fast_non_dominated_sort!(records, s.sense)
    fronts = SortedDict{UInt16, Vector{NSGAiiRecord}}()
    for r in records 
        if haskey(fronts, r.rank)
            push!(fronts[r.rank], r)
        else
            fronts[r.rank] = [r]
        end
    end
    sorted_recs = [crowding_distance_assignment!(s, front)
                   for front in values(fronts)]
    # for (n, front) in fronts
    #     println("--------")
    #     println(n)
    #     for r in front
    #         println(r)
    #     end
    # end
    vs = reduce(vcat, sorted_recs)
    # println("------------")
    # for v in vs
    #     println(v)
    # end
    vs
end

function(s::NSGAiiSelector)(records::Vector{NSGAiiRecord{T}}) where T
    fast_non_dominated_sort!(records, s.sense)
    fronts = SortedDict{UInt16, Vector{NSGAiiRecord}}()
    for r in records 
        if haskey(fronts, r.rank)
            push!(fronts[r.rank], r)
        else
            fronts[r.rank] = [r]
        end
    end
    sorted_recs = [crowding_distance_assignment!(s, front)
                   for front in values(fronts)]
    vs = reduce(vcat, sorted_recs)
    vs
end

function make_records(genos::Set{<:Genotype}, outcomes::Set{ScalarOutcome}) 
    odict = Dict{String, SortedDict{String, Float64}}()
    for o in outcomes
        for r in o.results
            if r.key ∉ keys(odict)
                odict[r.key] = SortedDict(r.testkey => r.score)
            else
                odict[r.key][r.testkey] = r.score
            end

        end
    end
    gdict = Dict{String, Genotype}(genos)
    [NSGAiiRecord(geno, odict[key]) for geno in values(gdict)]
end

function(s::NSGAiiSelector)(genos::Set{<:Genotype}, outcomes::Set{ScalarOutcome})
    records = make_records(genos, outcomes)
    s(records)
end
