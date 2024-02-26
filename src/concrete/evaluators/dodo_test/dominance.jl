export child_dominates_parent, get_dominant_children

using ....Abstract
using ...Matrices.Outcome
using ...Evaluators.NSGAII
using ...Criteria

function child_dominates_parent(child::Individual, matrix::OutcomeMatrix)
    if !(child.parent_id in matrix.row_ids)
        return true
    end
    parent_outcomes = matrix[child.parent_id, :]
    child_outcomes = matrix[child.id, :]
    child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
    return child_dominates_parent
end

function get_dominant_children(species, matrix, cluster_ids, claimed_parents)
    all_child_ids = [child.id for child in species.children if !(child.parent_id in claimed_parents)]
    child_ids = [id for id in cluster_ids if id in all_child_ids]
    children = [child for child in species.children if child.id in child_ids]
    dominant_children = [
        child for child in children if child_dominates_parent(child, matrix)
    ]
    return dominant_children
end

function get_dominant_children(
    promotions::DodoPromotions, records::Vector{R}, child_records::Vector{R}
) where R <: DodoTestRecord
    dominant_children = R[]
    for child_record in child_records
        parent_record = findfirst(r -> r.id == child_record.individual.parent_id, records)
        if parent_record === nothing
            error("Parent record not found for child record")
        elseif parent_record.id in promotions.hillclimber_to_retire_ids
            continue
        end
        child_outcomes = child_record.outcomes
        parent_outcomes = parent_record.outcomes
        child_dominates_parent = dominates(Maximize(), child_outcomes, parent_outcomes)
        if child_dominates_parent
            push!(dominant_children, child_record)
            break
        end
    end
    return dominant_children
end