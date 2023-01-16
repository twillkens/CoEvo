export Spawner

function(r::Reproducer)(popkey::String, curr_id::Int, singles::Vector{Genotype})
    children = Set{Genotype}()
    for parent in singles
        childkey = join([popkey, curr_id], KEY_SPLIT_TOKEN)  
        child = (r)(childkey, parent)
        push!(children, child)
        curr_id += 1
    end
    children, curr_id
end

function(r::Reproducer)(popkey::String, curr_id::Int,
                                 couples::Vector{Tuple{Genotype, Genotype}})
    children = Set{Genotype}()
    for (mother, father) in couples
        childkey = join([popkey, curr_id], KEY_SPLIT_TOKEN)  
        child = (r)(childkey, mother, father)
        push!(children, child)
        curr_id += 1
    end
    children, curr_id
end

function(r::Reproducer)(poptype::Type{<:Population}, 
        pop::Population, outcomes::Set{<:Outcome}, selections::GenoSelections)
    elites = selections.elites
    children1, curr_id = (r)(pop.key, pop.curr_id, selections.singles)
    children2, curr_id = (r)(pop.key, curr_id, selections.couples)
    nextgen = Set(union(elites, children1, children2))
    poptype(pop, outcomes, curr_id, nextgen)
end

function(r::Reproducer)(poptype::Type{<:Population}, 
        pop::Population, outcomes::Set{<:Outcome}, selections::Set{<:Selections})
    Set([(r)(poptype, pop, outcomes, selection) for selection in selections])
end

@Base.kwdef struct Spawner{S <: Selector, R <: Reproducer}
    key::String
    selector::S
    reproducer::R
    poptype::Type{<:Population}
end

function(s::Spawner)(pops::Set{<:Population}, outcomes::Set{<:Outcome})
    pop = Dict{String, Population}(pops)[s.key]
    selections = s.selector(pop, outcomes)
    s.reproducer(s.poptype, pop, outcomes, selections)
end




