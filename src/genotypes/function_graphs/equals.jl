

function Base.:(==)(a::FunctionGraphConnection, b::FunctionGraphConnection)
    return a.input_node_id == b.input_node_id && 
           isapprox(a.weight, b.weight) && 
           a.is_recurrent == b.is_recurrent
end

function Base.hash(a::FunctionGraphConnection, h::UInt)
    return hash(a.input_node_id, hash(a.weight, hash(a.is_recurrent, h)))
end


function Base.:(==)(a::FunctionGraphNode, b::FunctionGraphNode)
    return a.id == b.id && 
           a.func == b.func && 
           a.input_connections == b.input_connections  # Note: relies on `==` for FunctionGraphConnection
end

function Base.hash(a::FunctionGraphNode, h::UInt)
    return hash(a.id, hash(a.func, hash(a.input_connections, h)))  # Note: relies on `hash` for FunctionGraphConnection
end

function Base.:(==)(a::FunctionGraphGenotype, b::FunctionGraphGenotype)
    # Check each field for equality
    return a.input_node_ids == b.input_node_ids && 
           a.bias_node_ids == b.bias_node_ids &&
           a.hidden_node_ids == b.hidden_node_ids &&
           a.output_node_ids == b.output_node_ids &&
           a.nodes == b.nodes  # Note: relies on `==` for FunctionGraphNode
end
