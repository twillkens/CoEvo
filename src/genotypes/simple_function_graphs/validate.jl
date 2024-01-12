export validate_genotype, has_cycle_nonrecurrent

function has_cycle_nonrecurrent(genotype::SimpleFunctionGraphGenotype, start_node_id::Int)
    visited = Set{Int}()
    
    function reverse_dfs(node_id::Int, origin_id::Int)
        if node_id in visited
            return false
        end
        push!(visited, node_id)
        for node in genotype.nodes
            for edge in node.edges
                if !edge.is_recurrent && edge.target == node_id
                    if node.id == origin_id || reverse_dfs(node.id, origin_id)
                        return true
                    end
                end
                if !edge.is_recurrent && edge.target == node.id
                    return true
                end
            end
        end
        return false
    end

    return reverse_dfs(start_node_id, start_node_id)
end

function has_cycle_nonrecurrent(genotype::SimpleFunctionGraphGenotype)
    for node in genotype.nodes
        if has_cycle_nonrecurrent(genotype, node.id)
            return true
        end
    end
    return false
end

function validate_genotype(genotype::SimpleFunctionGraphGenotype, last_mutation::String)
    # 1. Ensure Unique IDs
    ids = Set{Int}()
    for node in genotype.nodes
        id = node.id
        if id in ids
            println("genotype = ", genotype)
            println("last_mutation = ", last_mutation)
            throw(ErrorException("Duplicate node ID"))
        end
        push!(ids, id)
    end
    
    # 2. Output Node Constraints 
    for node in genotype.nodes
        for edge in node.edges
            if edge.target in genotype.output_ids
                println("genotype = ", genotype)
                println("last_mutation = ", last_mutation)
                throw(ErrorException("Output node serving as input"))
            end
        end
    end
    
    # 3. Ensure Proper Arity
    for node in genotype.nodes
        expected_arity = FUNCTION_MAP[node.func].arity
        if length(node.edges) != expected_arity
            println("genotype = ", genotype)
            println("last_mutation = ", last_mutation)
            throw(ErrorException("Incorrect arity for function $(node.func)"))
        end
    end
    # 4. Validate Targets
    for node in genotype.nodes
        for edge in node.edges
            if !(edge.target in genotype.node_ids)
                println("genotype = ", genotype)
                println("last_mutation = ", last_mutation)
                throw(ErrorException("Invalid target for edge $edge"))
            end
        end
    end

    # 5. Validate Nonrecurrent Edges
    if has_cycle_nonrecurrent(genotype)
        println("genotype = ", genotype)
        println("last_mutation = ", last_mutation)
        throw(ErrorException("Non-recurrent cycle detected"))
    end

    for node in genotype.nodes
        for edge in node.edges
            if edge.source != node.id
                println("genotype = ", genotype)
                println("edge = ", edge)
                println("last_mutation = ", last_mutation)
                throw(ErrorException("Edge source is not node ID"))
            end
        end
    end
end