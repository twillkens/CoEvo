export clone_node!  

using ....Abstract: Mutator

function clone_node!(genotype::FunctionGraphGenotype, state::State)
    #println("genotype_before = $genotype")
    new_id = step!(state.gene_id_counter)
    parent_node = rand(state.rng, genotype.hidden_nodes)
    clone_node = deepcopy(parent_node)
    clone_node.id = new_id
    for edge in clone_node.edges
        edge.source = new_id
    end
    
    push!(genotype.nodes, clone_node)
    #println("genotype_after = $genotype")
end

clone_node!(genotype::FunctionGraphGenotype, ::Mutator, state::State) = 
    clone_node!(genotype, state)
    
