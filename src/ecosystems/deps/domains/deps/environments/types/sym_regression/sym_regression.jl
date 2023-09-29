module SymRegression

using ...Base.Common
using ...Base.Indivs.VectorSubstrate: VectorGeno
using ...Base.Indivs.GP
import ...Base.Jobs: stir
using Random

export SymbolicRegressionDomain, stir, SymbolicRegressionGenoCfg

Base.@kwdef struct SymbolicRegressionDomain <: Domain 
    func::Function
    symbols::Vector{Symbol}
end

struct SymbolicRegressionGenoCfg <: GenoConfig
    tests::Vector{Vector{Float64}}
end

function SymbolicRegressionGenoCfg(
    unit_range::UnitRange{Int}, 
)
    tests = [[i] for i in unit_range]
    SymbolicRegressionGenoCfg(tests)
end


function(genocfg::SymbolicRegressionGenoCfg)(
    ::AbstractRNG, sc::SpawnCounter, ::Int
)
    [VectorGeno(gids!(sc, length(test)), test) for test in genocfg.tests]
end

function stir(
    oid::Symbol, env::SymbolicRegressionDomain, ::ObsConfig,
    subject::ConstantGPPheno, test::Pheno{Vector{Float64}}
)
    subject.x.val = test.pheno[1]
    subject_y = eval(subject.expr)
    test_y = env.func(test.pheno...)
    score = abs(test_y - subject_y)
    Outcome(oid, subject => score, test => -score, NullObs())
end

function stir(
    oid::Symbol, env::SymbolicRegressionDomain, ::ObsConfig,
    subject::Pheno{Expr}, test::Pheno{Vector{Float64}}
)
    symbol_dict = Dict(
        symb => test.pheno[i] 
        for (i, symb) in enumerate(env.symbols)
    )
    expr = compile(subject.pheno, symbol_dict, false)
    subject_y = eval(expr)
    test_y = env.func(test.pheno...)
    score = abs(test_y - subject_y)
    Outcome(oid, subject => score, test => -score, NullObs())
end

function stir(
    oid::Symbol, env::SymbolicRegressionDomain, ::ObsConfig,
    subject::Pheno{Float64}, test::Pheno{Vector{Float64}}
)
    subject_y = subject.pheno
    test_y = env.func(test.pheno...)
    score = abs(test_y - subject_y)
    Outcome(oid, subject => score, test => -score, NullObs())
end

function stir(
    oid::Symbol, env::SymbolicRegressionDomain, ::ObsConfig,
    subject::Pheno{Symbol}, test::Pheno{Vector{Float64}}
)
    subject_y = test.pheno[1]
    test_y = env.func(test.pheno...)
    score = abs(test_y - subject_y)
    Outcome(oid, subject => score, test => -score, NullObs())
end

end