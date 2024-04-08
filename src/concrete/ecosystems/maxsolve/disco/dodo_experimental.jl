function get_high_rank_records(cluster_ids::Vector{Int}, records::Vector{<:NewDodoRecord})
    cluster_records = [record for record in records if record.id in cluster_ids]
    if length(cluster_records) != length(cluster_ids)
        println("CLUSTER_RECORDS = ", [record.id for record in cluster_records])
        println("CLUSTER_IDS = ", cluster_ids)
        error("Cluster records and cluster ids do not match")
    end
    highest_rank = first(cluster_records).rank
    high_rank_records = [record for record in cluster_records if record.rank == highest_rank]
    return high_rank_records
end


function get_cluster_leader_id(
    cluster_ids::Vector{Int}, records::Vector{<:NewDodoRecord}
)
    high_rank_records = get_high_rank_records(cluster_ids, records)
    #parent_records = [
    #    record for record in high_rank_records if record.individual in species.parents
    #]
    #other_records = [record for record in high_rank_records if !(record in parent_records)]
    #chosen_record = length(other_records) > 0 ? rand(other_records) : rand(parent_records)
    chosen_record = rand(high_rank_records)
    id = chosen_record.id
    return id
end

function get_cluster_leader_ids(
    all_cluster_ids::Vector{Vector{Int}}, 
    records::Vector{<:NewDodoRecord}
)
    leader_ids = [
        get_cluster_leader_id(cluster_ids, records) for cluster_ids in all_cluster_ids
    ]
    return leader_ids
end