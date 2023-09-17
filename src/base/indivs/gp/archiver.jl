export GPIndivArchiver

Base.@kwdef struct GPIndivArchiver <: Archiver 
    symtable::Dict{String, Any} = Dict(
        "+" => +,
        "-" => -,
        "*" => *,
        "/" => /,
        "psin" => psin,
        "iflt" => iflt,
        ":read" => :read,
    )
end

function substitute(val::Any, symtable::Dict{String, Any})
    if typeof(val) == String
        symtable[string(val)]
    else
        val
    end
end

function(a::GPIndivArchiver)(genes_group::JLD2.Group, gid::Int, gene::ExprNode)
    gene_group = make_group!(genes_group, gid)
    gene_group["parent_gid"] = gene.parent_gid
    gene_group["val"] = typeof(gene.val) == Real ? gene.val : string(gene.val)
    gene_group["child_gids"] = gene.child_gids
end
# Save an genotype to a JLD2.Group
function(a::GPIndivArchiver)(geno_group::JLD2.Group, geno::GPGeno)
    geno_group["root_gid"] = geno.root_gid
    genes_group = make_group!(geno_group, "genes")
    [a(genes_group, gid, gene) for (gid, gene) in geno.funcs]
end

# Save an individual to a JLD2.Group
function(a::GPIndivArchiver)(
    children_group::JLD2.Group, child::GPIndiv,
)
    cgroup = make_group!(children_group, child.iid)
    cgroup["pids"] = child.pids
    geno_group = make_group!(cgroup, "geno")
    a(geno_group, child.geno)
end

# Load a genotype from a JLD2.Group
function(a::GPIndivArchiver)(geno_group::JLD2.Group)
    root_gid = geno_group["root_gid"]
    genes = [
        ExprNode(
            parse(Int, gid),
            geno_group["genes"][gid]["parent_gid"],
            substitute(geno_group["genes"][gid]["val"], a.symtable),
            geno_group["genes"][gid]["child_gids"],
        ) for gid in keys(geno_group["genes"])
    ]
    terms = Dict(gene.gid => gene for gene in genes if length(gene.child_gids) == 0)
    funcs = Dict(gene.gid => gene for gene in genes if length(gene.child_gids) > 0)
    GPGeno(root_gid, funcs, terms)
end


# Load an individual from a JLD2.Group given its spid and iid
function(a::GPIndivArchiver)(spid::Symbol, iid::Int, igroup::JLD2.Group)
    pids = igroup["pids"]
    geno = a(igroup["geno"])
    GPIndiv(IndivKey(spid, iid), geno, pids)
end

function(a::GPIndivArchiver)(spid::String, iid::String, igroup::JLD2.Group)
    a(Symbol(spid), parse(Int, iid), igroup)
end