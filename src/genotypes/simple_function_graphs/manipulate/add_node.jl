export add_node!  

using ...Abstract: Mutator
export create_edge!

using Distributions: Uniform


function add_node!(genotype::SimpleFunctionGraphGenotype, mutator::Mutator, state::State)
    #println("genotype_before = $genotype")
    new_id = count!(state.gene_id_counter)
    func = FUNCTION_MAP[rand(state.rng, mutator.function_set)]
    bias = 0.0f0 #get_random_bias_value(mutator, state)
    node = Node(id = new_id, func = func.name, bias = bias,)
    for _ in 1:func.arity
        create_edge!(node, genotype, mutator, state)
    end
    push!(genotype.nodes, node)
    #println("genotype_after = $genotype")
end