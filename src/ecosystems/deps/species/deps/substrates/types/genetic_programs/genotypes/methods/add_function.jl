
export add_function

using .....CoEvo.Abstract: Mutator

"""
    add_function(geno::BasicGeneticProgramGenotype, newnode_id::Real, 
                 newnode_val::Union{FuncAlias}, newnode_child_ids::Vector{<:Real},
                 newnode_child_vals::Vector{<:Terminal})

Create and add a new function node along with its terminals to a copied version of the genotype.
The new function node and its terminals are initially disconnected from the genotype's execution tree.
They may be connected later through a swap operation.

Returns:
- A modified genotype with the new function node and its terminals added.

Throws:
- Error if the new node's ID already exists in the genotype.
"""
function add_function(
    geno::BasicGeneticProgramGenotype, 
    newnode_id::Real, 
    newnode_val::Union{FuncAlias},
    newnode_child_ids::Vector{<:Real},
    newnode_child_vals::Vector{<:Terminal},
)
    geno = deepcopy(geno)
    new_child_nodes = [
        ExpressionNodeGene(
            newnode_child_ids[i], 
            newnode_id, 
            newnode_child_vals[i], 
            ExpressionNodeGene[]
        ) 
        for i in 1:length(newnode_child_ids)
    ]
    new_node = ExpressionNodeGene(newnode_id, nothing, newnode_val, newnode_child_ids)
    push!(geno.functions, new_node.id => new_node)
    [push!(geno.terminals, child.id => child) for child in new_child_nodes]
    geno
end