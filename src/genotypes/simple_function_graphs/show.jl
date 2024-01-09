
function Base.show(io::IO, genotype::SimpleFunctionGraphGenotype)
    for node in genotype.nodes
        print(io, "(", node.id, ", :", node.func, ", [")
        edges = [edge.target for edge in node.edges]
        print(io, join(edges, ", "))
        println(io, "])")
    end
end
