export DodoPromotions, DodoTestRecord, get_cluster_records, get_hillclimber_records
export promote_child!, promote_explorer_or_retiree!, update_promotions!

using ....Abstract

get_cluster_records(
    species::AbstractSpecies, 
    records::Vector{<:DodoTestRecord}, 
    cluster_ids::Vector{Int}
) = [
    record for record in records 
        if record.id in cluster_ids && !(record.individual in species.hillclimbers)
]

function check_if_all_are_explorers_or_retirees(
    records::Vector{<:DodoTestRecord}, species::AbstractSpecies
)
    all_are_explorers_or_retirees = all(
        record -> record.individual in [species.explorers ; species.retirees] , records
    )
    return all_are_explorers_or_retirees
end


function promote_explorer_or_retiree!(
    promotions::DodoPromotions, record::DodoTestRecord, species::AbstractSpecies
)
    if record.individual in species.explorers
        push!(promotions.explorer_to_promote_ids, record.id)
    else
        push!(promotions.retiree_to_promote_ids, record.id)
    end
end

function promote_child!(promotions::DodoPromotions, record::DodoTestRecord)
    push!(promotions.child_to_promote_ids, record.id)
    push!(promotions.hillclimber_to_retire_ids, record.individual.parent_id)
end

function update_promotions!(
    promotions::DodoPromotions, 
    species::AbstractSpecies, 
    records::Vector{<:DodoTestRecord}, 
    cluster_ids::Vector{Int},
)
    cluster_records = get_cluster_records(species, records, cluster_ids)
    if length(cluster_records) == 0
        return
    end
    all_are_explorers_or_retirees = check_if_all_are_explorers_or_retirees(cluster_records, species)
    #println("-----")
    #println("CLUSTER_IDS = ", cluster_ids)
    #println("all_are_explorers_or_retirees = ", all_are_explorers_or_retirees)
    if all_are_explorers_or_retirees
        record = first(cluster_records)
        #println("record = ", record)
        promote_explorer_or_retiree!(promotions, record, species)
    else
        cluster_records = [record for record in cluster_records if record.individual in species.children]
        dominant_children = get_dominant_children(promotions, records, cluster_records)
        if length(dominant_children) > 0
            child_to_promote = first(dominant_children)
            promote_child!(promotions, child_to_promote)
        end
    end
end

function update_promotions_lax!(
    promotions::DodoPromotions, 
    species::AbstractSpecies, 
    records::Vector{<:DodoTestRecord}, 
    cluster_ids::Vector{Int},
)
    cluster_records = get_cluster_records(species, records, cluster_ids)
    if length(cluster_records) == 0
        return
    end
    top_rank = first(cluster_records).rank
    nondominated = [record for record in cluster_records if record.rank == top_rank]
    hillclimber_nondominated = [record for record in nondominated if record.individual in species.hillclimbers]
    if length(hillclimber_nondominated) > 0
        new_hillclimber = first(hillclimber_nondominated)
        push!(promotions.new_hillclimber_ids, new_hillclimber.individual.id)
        other_hillclimber_ids = [record.individual.id for record in hillclimber_nondominated[2:end]]
        append!(promotions.hillclimber_to_retire_ids, other_hillclimber_ids)
        return
    end
    others_nondominated = [record for record in nondominated if !(record.individual in species.hillclimbers)]
    new_hillclimber = rand(others_nondominated)
    push!(promotions.new_hillclimber_ids, new_hillclimber.individual.id)
end

get_hillclimber_records(species::AbstractSpecies, records::Vector{<:DodoTestRecord}) = [
    record for record in records if record.individual in species.hillclimbers
]

function DodoPromotions(
    species::AbstractSpecies, 
    records::Vector{<:DodoTestRecord},
    all_cluster_ids::Vector{Vector{Int}},
)
    promotions = DodoPromotions()
    println("--------")
    #println("HILLCLIMBER_IDS = ", sort([record.individual.id for record in records if record.individual in species.hillclimbers]))
    #println("CHILD_IDS = ", sort([record.individual.id for record in records if record.individual in species.children]))
    #println("EXPLORER_IDS = ", sort([record.individual.id for record in records if record.individual in species.explorers]))
    #println("RETIREES_IDS = ", sort([record.individual.id for record in records if record.individual in species.retirees]))
    for cluster_ids in all_cluster_ids
        update_promotions!(promotions, species, records, cluster_ids)
        #update_promotions_lax!(promotions, species, records, cluster_ids)
    end
    #for explorer in species.explorers
    #    if explorer.id in promotions.new_hillclimber_ids
    #        push!(promotions.explorer_to_promote_ids, explorer.id)
    #    end
    #end
    #for retiree in species.retirees
    #    if retiree.id in promotions.new_hillclimber_ids
    #        push!(promotions.retiree_to_promote_ids, retiree.id)
    #    end
    #end
    ##for hillclimber in species.hillclimbers
    ##    if !(hillclimber.id in promotions.new_hillclimber_ids)
    ##        push!(promotions.hillclimber_to_retire_ids, hillclimber.id)
    ##    end
    ##end
    #for child in species.children
    #    if child.id in promotions.new_hillclimber_ids
    #        push!(promotions.child_to_promote_ids, child.id)
    #    end
    #end
    println("N_PROMOTED_EXPLORERS = ", length(promotions.explorer_to_promote_ids))
    println("N_PROMOTED_CHILDREN = ", length(promotions.child_to_promote_ids))
    println("N_PROMOTED_RETIREES = ", length(promotions.retiree_to_promote_ids))
    return promotions
end