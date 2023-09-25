
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


# For each gene, we create a new group identified by the gene's gid
# and save the gene's parent_gid, val, and child_gids
# The val is saved as a string if it is a symbol or function using the 
# symbol_table specified in the archiver; otherwise it is saved as is
function(a::GPGenoArchiver)(genes_group::JLD2.Group, gid::Int, gene::ExpressionNodeGene)
    symbol_table_inv = Dict(value => key for (key, value) in a.symbol_table)
    gene_group = make_group!(genes_group, gid)
    gene_group["parent_gid"] = gene.parent_gid
    gene_group["val"] = gene.val in keys(symbol_table_inv) ? 
        symbol_table_inv[gene.val] : gene.val
    gene_group["child_gids"] = gene.child_gids
end

# Save an genotype to a JLD2.Group
function(a::GPGenoArchiver)(geno_group::JLD2.Group, geno::BasicGeneticProgramGenotype)
    geno_group["root_gid"] = geno.root_gid
    genes_group = make_group!(geno_group, "genes")
    [a(genes_group, gid, gene) for (gid, gene) in all_nodes(geno)]
end


function substitute(val::Any, symbol_table::Dict{String, Any})
    val in keys(symbol_table) ? symbol_table[val] : val
end
# Load a genotype from a JLD2.Group
function(a::GPGenoArchiver)(geno_group::JLD2.Group)
    root_gid = geno_group["root_gid"]
    genes = [
        ExpressionNodeGene(
            parse(Int, gid),
            geno_group["genes/$gid/parent_gid"],
            substitute(geno_group["genes/$gid/val"], a.symtable),
            geno_group["genes/$gid/child_gids"],
        ) for gid in keys(geno_group["genes"])
    ]
    terms = Dict(gene.gid => gene for gene in genes if length(gene.child_gids) == 0)
    funcs = Dict(gene.gid => gene for gene in genes if length(gene.child_gids) > 0)
    BasicGeneticProgramGenotype(root_gid, funcs, terms)
end