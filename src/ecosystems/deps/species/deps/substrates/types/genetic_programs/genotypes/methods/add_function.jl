
export add_function

using .....CoEvo.Abstract: Mutator

# Make a copy of the genotype and create the new function node and its terminals
# before adding to the genotype func and term dicts.
# By default a new function and its terminals are disconnected from the rest of the 
# genotype and execution tree. It may be added later through a swap operation
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