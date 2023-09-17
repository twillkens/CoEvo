export GPPheno
# The GPPheno is a phenotype for a GPIndiv. It is an Expr that can be evaluated 
# to produce a value.
struct GPPheno <: Phenotype
    ikey::IndivKey
    expr::Expr
end

# This recursively converts an ExprNode in a GPGeno to an Expr that can be evaluated.
function Base.Expr(geno::GPGeno, enode::ExprNode)
    # If the node is a terminal, return the value
    if isa(enode.val, Symbol) || isa(enode.val, Real)
        return enode.val
    else
        # If the node is a function, recursively convert the children to Exprs
        child_nodes = get_child_nodes(geno, enode)
        child_exprs = [Expr(geno, child_node) for child_node in child_nodes]
        return Expr(:call, enode.val, child_exprs...)
    end
end

# This recursively converts a GPGeno to an Expr that can be evaluated, starting from the 
# root node of the execution tree.
function Base.Expr(geno::GPGeno)
    root_node = get_root(geno)
    Expr(geno, root_node)
end

function(pcfg::DefaultPhenoCfg)(geno::GPGeno)
    GPPheno(geno.ikey, Expr(geno))
end