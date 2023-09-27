

export GPGenoArchiver

# Used for saving and loading GPGenos to/from JLD2 files
# The symtable is a dictionary of strings to symbols to functions
Base.@kwdef struct GPGenoArchiver <: Archiver 
    symbol_table::Dict{String, Any} = Dict(
        "+" => +,
        "-" => -,
        "*" => *,
        "/" => /,
        "psin" => psin,
        "iflt" => iflt,
        ":read" => :read,
    )
end


# For each gene, we create a new group identified by the gene's id
# and save the gene's parent_id, val, and child_ids
# The val is saved as a string if it is a symbol or function using the 
# symbol_table specified in the archiver; otherwise it is saved as is
function(a::GPGenoArchiver)(genes_group::JLD2.Group, id::Int, gene::ExpressionNodeGene)
    symbol_table_inv = Dict(value => key for (key, value) in a.symbol_table)
    gene_group = make_group!(genes_group, id)
    gene_group["parent_id"] = gene.parent_id
    gene_group["val"] = gene.val in keys(symbol_table_inv) ? 
        symbol_table_inv[gene.val] : gene.val
    gene_group["child_ids"] = gene.child_ids
end

# Save an genotype to a JLD2.Group
function(a::GPGenoArchiver)(geno_group::JLD2.Group, geno::BasicGeneticProgramGenotype)
    geno_group["root_id"] = geno.root_id
    genes_group = make_group!(geno_group, "genes")
    [a(genes_group, id, gene) for (id, gene) in all_nodes(geno)]
end


function substitute(val::Any, symbol_table::Dict{String, Any})
    val in keys(symbol_table) ? symbol_table[val] : val
end
# Load a genotype from a JLD2.Group
function(a::GPGenoArchiver)(geno_group::JLD2.Group)
    root_id = geno_group["root_id"]
    genes = [
        ExpressionNodeGene(
            parse(Int, id),
            geno_group["genes/$id/parent_id"],
            substitute(geno_group["genes/$id/val"], a.symtable),
            geno_group["genes/$id/child_ids"],
        ) for id in keys(geno_group["genes"])
    ]
    terminals = Dict(gene.id => gene for gene in genes if length(gene.child_ids) == 0)
    functions = Dict(gene.id => gene for gene in genes if length(gene.child_ids) > 0)
    BasicGeneticProgramGenotype(root_id, functions, terminals)
end