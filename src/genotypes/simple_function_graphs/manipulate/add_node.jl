export add_node!  

using ...Abstract: Mutator

function add_node!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    #println("genotype_before = $genotype")
    new_id = count!(state.gene_id_counter)
    func = FUNCTION_MAP[rand(state.rng, mutator.function_set)]
    node = SimpleFunctionGraphNode(id = new_id, func = func.name, edges = [])
    for _ in 1:func.arity
        edge = create_edge(genotype, node, mutator, state)
        push!(node.edges, edge)
    end
    push!(genotype.nodes, node)
    #println("genotype_after = $genotype")
end