export ModesStats

function getchanges(allfsets::Vector{<:Set{<:Genotype}})
    changes = [length(allfsets[1])]
    for i in 2:(length(allfsets))
        prevgenos = allfsets[i - 1]
        currgenos = allfsets[i]
        change = length([geno for geno in currgenos if geno ∉ prevgenos])
        push!(changes, change)
    end
    changes
end

function getnovelties(allfsets::Vector{<:Set{<:Genotype}})
    novelties = [length(allfsets[1])]
    allgenos = Set([geno for geno in allfsets[1]])
    for i in 2:(length(allfsets))
        currgenos = allfsets[i]
        novelty = length([geno for geno in currgenos if geno ∉ allgenos])
        push!(novelties, novelty)
        union!(allgenos, currgenos)
    end
    novelties
end

function getcomplexities(allfsets::Vector{<:Set{<:Genotype}})
    complexities = Int[]
    for i in 1:(length(allfsets))
        currgenos = allfsets[i]
        complexity = maximum([length(geno) for geno in currgenos])
        push!(complexities, complexity)
    end
    complexities
end

function getecologies(
    allfvecs::Vector{<:Vector{<:Genotype}}, allfsets::Vector{<:Set{<:Genotype}}
)
    ecologies = Float64[]
    for (fvec, fset) in zip(allfvecs, allfsets)
        pcs = Float64[]
        for s in fset
            pc = 0
            for v in fvec
                if v == s
                    pc += 1
                end
            end
            push!(pcs, pc / length(fvec))
        end
        push!(ecologies, -sum(pc * log(2, pc) for pc in pcs))
    end
    ecologies
end
function get_spstats_dict(
    trial::Int, 
    spid::String,
    all_records::Vector{Vector{ModesPruneRecord}}
)   
    d = Dict{String, Vector{Float64}}()
    #println(spid)
    #println(length(all_records))
    for prunelevel in ["full", "hopcroft", "visit", "age"]#["full", "hopcroft", "visit", "age"]
        prunegenovecs = [
            [record.prunegenos[prunelevel] for record in records] 
            for records in all_records
        ]
        genovecs = [[prunegeno.geno for prunegeno in prunegenovec] for prunegenovec in prunegenovecs]
        genosets = [Set(genovec) for genovec in genovecs]
        #println(prunelevel)
        #println(genovecs[1])
        #println(genosets[1])
        d["$(spid)-$(prunelevel)-fitness-$(trial)"] = [
            mean([prunegeno.fitness for prunegeno in prunegenos]) 
            for prunegenos in prunegenovecs
        ]
        d["$(spid)-$(prunelevel)-eplen-$(trial)"] = [
            mean([prunegeno.eplen for prunegeno in prunegenos]) 
            for prunegenos in prunegenovecs
        ]
        d["$(spid)-$(prunelevel)-levdist-$(trial)"] = [
            mean([prunegeno.levdist for prunegeno in prunegenos]) 
            for prunegenos in prunegenovecs
        ]
        d["$(spid)-$(prunelevel)-coverage-$(trial)"] = [
            mean([prunegeno.coverage for prunegeno in prunegenos]) 
            for prunegenos in prunegenovecs
        ]
        d["$(spid)-$(prunelevel)-change-$(trial)"] = getchanges(genosets)
        d["$(spid)-$(prunelevel)-novelty-$(trial)"] = getnovelties(genosets)
        d["$(spid)-$(prunelevel)-complexity-$(trial)"] = getcomplexities(genosets)
        d["$(spid)-$(prunelevel)-ecology-$(trial)"] = getecologies(genovecs, genosets)
    end
    d
end

function combine_value_vectors(dict::Dict{String, Vector{Vector{T}}}) where T
    # Get the length of the value vectors
    vector_length = length(first(values(dict)))
    #println("vector length: $vector_length")

    # Create an empty vector to store the combined vectors
    combined_vector = Vector{Vector{T}}()

    # Iterate over each index in the value vectors
    for i in 1:vector_length
        # Create a temporary vector to store the combined elements at the current index
        combined_element = Vector{T}()

        # Iterate over each key-value pair in the dictionary
        for (_, vector) in pairs(dict)
            # Append the elements at the current index to the combined element
            append!(combined_element, vector[i])
        end

        # Append the combined element to the combined vector
        push!(combined_vector, combined_element)
    end

    return combined_vector
end

function get_trialstats(
    trial::Int,
    dict::Dict{String, Vector{Vector{ModesPruneRecord}}}, 
)
    trialstats = [get_spstats_dict(trial, spid, dict[spid]) for spid in keys(dict)]
    push!(trialstats, get_spstats_dict(trial, "eco", combine_value_vectors(dict)))
    merged_dict = deepcopy(trialstats[1])
    for dict in trialstats[2:end]
        merge!(merged_dict, dict)
    end
    merged_dict
end

#function getfitnesses(allfindivs::Vector{<:Vector{<:FilterIndiv}})
#    [mean([findiv.fitness for findiv in findivs]) for findivs in allfindivs]
#end
#
#struct ModesStats
#    change::Vector{Int}
#    novelty::Vector{Int}
#    complexity::Vector{Float64}
#    ecology::Vector{Float64}
#end
#
#function ModesStats(allfvecs::Vector{<:Vector{<:FSMGeno}})
#    allfsets = [Set(fgenos) for fgenos in allfvecs]
#    change = getchanges(allfsets)
#    novelty = getnovelties(allfsets)
#    complexity = getcomplexities(allfsets)
#    ecology = getecologies(allfvecs, allfsets)
#    ModesStats(change, novelty, complexity, ecology)
#end
#
#function ModesStats(all_records::Vector{Vector{ModesPruneRecord}})
#    allfvecs = [collect(values(record.prunegenos)) for record in all_records[1]]
#    ModesStats(allfvecs)
#end
#export SpeciesStats, EcoStats, FilterResults
#
#struct SpeciesStats
#    spid::String
#    genostats::Union{ModesStats, Nothing}
#    minstats::Union{ModesStats, Nothing}
#    modestats::ModesStats
#    minfitness::Vector{Float64}
#    modefitness::Vector{Float64}
#    min_eplen::Vector{Float64}
#    mode_eplen::Vector{Float64}
#    levdist::Vector{Float64}
#end
#
#function SpeciesStats(spid::String, allfindivs::Vector{<:Vector{<:FilterIndiv}})
#    println("getting stats for $spid")
#    genostats = ModesStats(
#        [[findiv.geno for findiv in findivs] 
#        for findivs in allfindivs]
#    )
#    mingenostats = ModesStats(
#        [[findiv.mingeno for findiv in findivs] 
#        for findivs in allfindivs]
#    )
#    modestats = ModesStats(
#        [[findiv.modegeno for findiv in findivs] 
#        for findivs in allfindivs]
#    )
#    minfitness = [mean(findiv.minfitness for findiv in findivs) for findivs in allfindivs]
#    modefitness = [mean(findiv.modefitness for findiv in findivs) for findivs in allfindivs]
#    min_eplen = [mean(findiv.min_eplen for findiv in findivs) for findivs in allfindivs]
#    mode_eplen = [mean(findiv.mode_eplen for findiv in findivs) for findivs in allfindivs]
#    levdist = [mean(findiv.levdist for findiv in findivs) for findivs in allfindivs]
#    #println("ends of all vecs: $(minfitness[end]), $(modefitness[end]), $(min_eplen[end]), $(mode_eplen[end]), $(levdist[end])")
#    SpeciesStats(
#        spid, 
#        genostats, mingenostats, modestats, 
#        minfitness, modefitness, 
#        min_eplen, mode_eplen,
#        levdist,
#    )
#end
#
#struct FilterResults{I <: FilterIndiv}
#    spid::String
#    t::Int
#    allfindivs::Vector{Vector{I}}
#    stats::SpeciesStats
#end
#
#struct EcoStats
#    eco::String
#    trial::Int
#    t::Int
#    stats::Union{SpeciesStats, Nothing}
#    spstats::Dict{String, SpeciesStats}
#end
#
#function EcoStats(
#    eco::String, trial::Int, t::Int, fdict::Dict{String, <:FilterResults}
#)
#    spstats = Dict(spid => fresults.stats for (spid, fresults) in fdict)
#    allindivs = [fresults.allfindivs for fresults in values(fdict)]
#    allindivs = collect(vcat(y...) for y in zip(allindivs...))
#    metastats = SpeciesStats(eco, allindivs)
#    EcoStats(
#        eco,
#        trial,
#        t,
#        metastats,
#        spstats, 
#    )
#end