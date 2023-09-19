using Test
using Random
using StableRNGs
using Distributed
@everywhere using CoEvo
using CoEvo.Base.Coev
using CoEvo.Base.Common
using CoEvo.Base.Reproduction
using CoEvo.Base.Indivs.GP
using CoEvo.Base.Indivs.GP: GPPheno
using CoEvo.Base.Indivs.GP: GPGeno, ExprNode, Terminal, GPMutator, FuncAlias
using CoEvo.Base.Indivs.GP: GPGenoCfg, GPGenoArchiver
using CoEvo.Base.Indivs.GP: get_node, get_child_index, get_ancestors, get_descendents
using CoEvo.Base.Indivs.GP: addfunc, rmfunc, swapnode, inject_noise, splicefunc
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin

using CoEvo.Domains.SymRegression
using CoEvo.Domains.SymRegression: stir
using CoEvo.Base.Jobs
using CoEvo.Domains.ContinuousPredictionGame

function my_challenge()
    GPGeno(
        root_gid = 1,
        funcs = Dict(
            1 => ExprNode(1, nothing, iflt, [5, 2, 8, 3]),
            2 => ExprNode(2, 1, +, [6, 7]),
            3 => ExprNode(3, 1, sin, [4]),
            4 => ExprNode(4, 3, *, [9, 10]),
            10 => ExprNode(10, 4, +, [11, 12]),
        ),
        terms = Dict(
            5 => ExprNode(5, 1, π),
            6 => ExprNode(6, 1, π),
            7 => ExprNode(7, 2, :read),
            8 => ExprNode(8, 1, :read),
            9 => ExprNode(9, 4, :read),
            11 => ExprNode(11, 10, :read),
            12 => ExprNode(12, 10, -3/2),
        ),
    )
end


pheno = GPPheno(IndivKey(:challenge, 1), my_challenge())
data = [0.0, π]
println("answer 1: ", spin(pheno, data))
data = [0.0, π, 0.0]
println("answer 2: ", spin(pheno, data))