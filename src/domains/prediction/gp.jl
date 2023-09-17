
abstract type TerminalFunctor end

mutable struct ConstantTerminalFunctor{T <: Real} <: TerminalFunctor
    val::T
end

function(terminal::ConstantTerminalFunctor)()
    terminal.val
end

mutable struct TapeReaderTerminalFunctor{T <: Real} <: TerminalFunctor
    head::Int
    tape::Vector{T}
end

function TapeReaderTerminalFunctor(tape::Vector{<:Real})
    TapeReaderTerminalFunctor(length(tape), tape)
end

function(r::TapeReaderTerminalFunctor)()
    val = r.tape[r.head]
    r.head = r.head == 1 ? Base.length(r.tape) : r.head - 1
    val
end

function symcompile(expr::Expr, tfs::Dict{Symbol, <:TerminalFunctor}, do_copy::Bool = true)
    expr = do_copy ? deepcopy(expr) : expr
    for i in 1:length(expr.args)
        arg = expr.args[i]
        if isa(arg, Symbol)
            expr.args[i] = Expr(:call, tfs[arg])
        elseif isa(arg, Expr)
            expr.args[i] = symcompile(arg, tfs)
        end
    end
    expr
end

function radianshift(x::Real)
    x - (floor(x / 2π) * 2π)
end

function simulate(n::Int, expr1::Expr, expr2::Expr)
    tape1, tape2 = [0.0], [0.0]
    tr1, tr2 = TapeReaderTerminalFunctor(tape1), TapeReaderTerminalFunctor(tape2)
    expr1, expr2 = symcompile(expr1, Dict(:read => tr1)), symcompile(expr2, Dict(:read => tr2))
    pos1, pos2 = 0.0, 0.0
    for i in 1:n - 1
        tr1.head, tr2.head = i, i 
        v1 = eval(expr1)
        v2 = eval(expr2)
        pos1, pos2 = radianshift(pos1 + v1), radianshift(pos2 + v2)
        diff1, diff2 = radianshift(pos2 - pos1), radianshift(pos1 - pos2)
        push!(tape1, diff1)
        push!(tape2, diff2)
    end
    tape1, tape2
end

function stir(
    oid::Symbol, domain::SymbolicRegression, obscfg::ObsConfig,
    pheno1::FSMPheno, pheno2::FSMPheno
)
    loopstart, states1, states2, traj1, traj2 = simulate(domain, pheno1, pheno2)
    score = 1
    obs = obscfg(loopstart, pheno1, pheno2, states1, states2, traj1, traj2)
    Outcome(oid, pheno1 => score, pheno2 => score, obs)
end