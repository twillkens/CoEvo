export splice_func

function splice_func(
    geno::BasicGeneticProgramGenotype, 
    splicer_top_gid::Int, 
    splicer_tail_gid::Int,
    splicee_gid::Int,
)
    geno = deepcopy(geno)

    splicer_top = get_node(geno, splicer_top_gid)
    splicer_parent = get_node(geno, splicer_top.parent_gid)
    splicer_tail = get_node(geno, splicer_tail_gid)
    splicer_bottom = get_node(geno, splicer_tail.parent_gid)
    splicee = get_node(geno, splicee_gid)
    splicee_parent = get_node(geno, splicee.parent_gid)

    # The splicer top replaces the splicee as the child of the splicee's parent
    if splicee_parent !== nothing
        splicer_top.parent_gid = splicee_parent.gid
        replace_child!(splicee_parent, splicee, splicer_top)
    else
        splicer_top.parent_gid = nothing
        geno.root_gid = splicer_top.gid
    end

    # The splicee then is attached to the splicer bottom, replacing the splicer tail
    splicee.parent_gid = splicer_bottom.gid
    replace_child!(splicer_bottom, splicer_tail, splicee)

    # The splicer tail then becomes the child of the splicer parent
    splicer_tail.parent_gid = splicer_parent === nothing ? nothing : splicer_parent.gid
    if splicer_parent !== nothing
        replace_child!(splicer_parent, splicer_top, splicer_tail)
    end

    if splicee_gid == geno.root_gid
        geno.root_gid = get_ancestors(geno, splicee)[end].gid
    end
    if splicer_top_gid == geno.root_gid
        ancestors = get_ancestors(geno, splicer_top)
        geno.root_gid = length(ancestors) > 0 ? ancestors[end].gid : splicer_top_gid
    end
    if splicer_tail_gid in keys(geno.terms) && 
            splicer_tail.parent_gid === nothing && 
            splicer_tail_gid !== geno.root_gid
        delete!(geno.terms, splicer_tail_gid)
    end
    geno
end

function splice_func(rng::AbstractRNG, ::SpawnCounter, ::BasicGeneticProgramMutator, geno::BasicGeneticProgramGenotype)
    # select a function node at random for splicer_top_gid
    if length(geno.funcs) == 0
        return deepcopy(geno)
    end
    splicer_top = rand(rng, collect(values(geno.funcs)))

    
    # Get all descendents of splicer_top_gid for potential splicer_tail_gid
    descendents = get_descendents(geno, splicer_top.gid)
    splicer_tail = rand(rng, descendents)

    # Identify all nodes not in the lineage of splicer_top and splicer_tail for splicee_gid
    lineage_nodes = [get_ancestors(geno, splicer_top.gid); splicer_top; descendents]
    lineage_gids = Set(n.gid for n in lineage_nodes)
    all_node_gids = Set(n.gid for n in values(all_nodes(geno)))
    spliceable = setdiff(all_node_gids, lineage_gids)
    
    # If there are no spliceable nodes, return original genotype
    if isempty(spliceable)
        return deepcopy(geno)
    end

    splicee_gid = rand(rng, spliceable)
    
    return splice_func(geno, splicer_top.gid, splicer_tail.gid, splicee_gid)
end