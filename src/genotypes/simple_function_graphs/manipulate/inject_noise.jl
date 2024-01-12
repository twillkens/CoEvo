export inject_noise!

function inject_noise!(node::Node, noise_values::Vector{Float32})
    for (edge, noise_value) in zip(node.edges, noise_values)
        edge.weight += noise_value
        if isinf(edge.weight) || isnan(edge.weight)
            println("node = $node")
            println("noise_values = $noise_values")
            throw(ErrorException("Invalid weight"))
        end
    end
end

function inject_noise!(
    genotype::SimpleFunctionGraphGenotype, noise_map::Dict{Int, Vector{Float32}}
)
    for node in genotype.nodes
        if haskey(noise_map, node.id)
            noise_values = noise_map[node.id]
            if length(node.edges) != length(noise_values)
                println("genotype = $genotype")
                println("noise_map = $noise_map")
                throw(ErrorException("Mismatched number of noise values"))
            end
            inject_noise!(node, noise_values)
        end
    end
end

function inject_noise!(
    rng::AbstractRNG, genotype::SimpleFunctionGraphGenotype; std_dev::Float32 = 0.1f0
)
    noise_map = Dict{Int, Vector{Float32}}()
    
    # Generating the noise_map
    for node in genotype.nodes
        if !isempty(node.edges)  # Only for nodes with edges
            noise_values = randn(rng, length(node.edges)) .* std_dev  # Assuming normal distribution for noise
            noise_map[node.id] = noise_values
        end
    end
    
    # Using deterministic function to inject noise
    inject_noise!(genotype, noise_map)
end

function inject_noise!(node::Node, mutator::Mutator, state::State)
    noise = randn(state.rng) * mutator.noise_std
    node.bias += noise
end

function inject_noise!(edge::Edge, mutator::Mutator, state::State)
    noise = randn(state.rng) * mutator.noise_std
    edge.weight += noise
end