export splice_function

function splice_function(
    geno::BasicGeneticProgramGenotype, 
    splicer_top_id::Int, 
    splicer_tail_id::Int,
    splicee_id::Int,
)
    geno = deepcopy(geno)

    splicer_parent = get_node(geno, splicer_top.parent_id)
    splicer_top = get_node(geno, splicer_top_id)
    splicer_bottom = get_node(geno, splicer_tail.parent_id)
    splicer_tail = get_node(geno, splicer_tail_id)

    splicee_parent = get_node(geno, splicee.parent_id)
    splicee = get_node(geno, splicee_id)

    # The splicer top replaces the splicee as the child of the splicee's parent
    if splicee_parent !== nothing
        splicer_top.parent_id = splicee_parent.id
        replace_child!(splicee_parent, splicee, splicer_top)
    else
        splicer_top.parent_id = nothing
        geno.root_id = splicer_top.id
    end

    # The splicee then is attached to the splicer bottom, replacing the splicer tail
    splicee.parent_id = splicer_bottom.id
    replace_child!(splicer_bottom, splicer_tail, splicee)

    # The splicer tail then becomes the child of the splicer parent
    splicer_tail.parent_id = splicer_parent === nothing ? nothing : splicer_parent.id
    if splicer_parent !== nothing
        replace_child!(splicer_parent, splicer_top, splicer_tail)
    end

    if splicee_id == geno.root_id
        geno.root_id = get_ancestors(geno, splicee)[end].id
    end
    if splicer_top_id == geno.root_id
        ancestors = get_ancestors(geno, splicer_top)
        geno.root_id = length(ancestors) > 0 ? ancestors[end].id : splicer_top_id
    end
    if splicer_tail_id in keys(geno.terminals) && 
            splicer_tail.parent_id === nothing && 
            splicer_tail_id !== geno.root_id
        delete!(geno.terminals, splicer_tail_id)
    end
    geno
end
