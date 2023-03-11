export ModesStats

function getchanges(allfsets::Vector{<:Set{<:FSMGeno}})
    changes = [length(allfsets[1])]
    for i in 2:(length(allfsets))
        prevgenos = allfsets[i - 1]
        currgenos = allfsets[i]
        change = length([geno for geno in currgenos if geno ∉ prevgenos])
        push!(changes, change)
    end
    changes
end

function getnovelties(allfsets::Vector{<:Set{<:FSMGeno}})
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

function getcomplexities(allfsets::Vector{<:Set{<:FSMGeno}})
    complexities = Int[]
    for i in 1:(length(allfsets))
        currgenos = allfsets[i]
        complexity = maximum([length(geno.ones) + length(geno.zeros) for geno in currgenos])
        push!(complexities, complexity)
    end
    complexities
end

function getecologies(
    allfvecs::Vector{<:Vector{<:FSMGeno}}, allfsets::Vector{<:Set{<:FSMGeno}}
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


function getfitnesses(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    [mean([findiv.fitness for findiv in findivs]) for findivs in allfindivs]
end

function geteplens(allfindivs::Vector{<:Vector{<:FilterIndiv}})
    ([mean([findiv.min_eplen for findiv in findivs]) for findivs in allfindivs],
    [mean([findiv.mode_eplen for findiv in findivs]) for findivs in allfindivs])
end

struct ModesStats
    change::Vector{Int}
    novelty::Vector{Int}
    complexity::Vector{Float64}
    ecology::Vector{Float64}
end

function ModesStats(allfvecs::Vector{<:Vector{<:FSMGeno}})
    allfsets = [Set(fgenos) for fgenos in allfvecs]
    change = getchanges(allfsets)
    novelty = getnovelties(allfsets)
    complexity = getcomplexities(allfsets)
    ecology = getecologies(allfvecs, allfsets)
    ModesStats(change, novelty, complexity, ecology)
end