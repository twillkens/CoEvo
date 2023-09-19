export GPPheno, symcompile, compile, ConstantGPPheno, TapeReaderGPPheno, ConstantGPPhenoCfg
export TapeReaderGPPhenoCfg, reset!, ConstantTerminalFunctor, TapeReaderTerminalFunctor
export TerminalFunctor, get_tape_copy
export ConstantTerminalFunctor, TapeReaderTerminalFunctor, DefaultPhenoCfg

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



abstract type TerminalFunctor end




function symcompile!(expr::Expr, tfs::Dict{Symbol, <:TerminalFunctor})
    for (i, arg) in enumerate(expr.args)
        if isa(arg, Symbol)
            expr.args[i] = Expr(:call, tfs[arg])
        elseif isa(arg, Expr)
            expr.args[i] = symcompile!(arg, tfs)
        end
    end
    expr
end

function compile(expr::Expr, symbol_dict::Dict{Symbol, <:Real}, do_copy::Bool = true)
    expr = do_copy ? deepcopy(expr) : expr
    for (i, arg) in enumerate(expr.args)
        if isa(arg, Symbol)
            expr.args[i] = symbol_dict[arg]
        elseif isa(arg, Expr)
            expr.args[i] = compile(arg, symbol_dict, false)
        end
    end
    expr
end


function(pcfg::DefaultPhenoCfg)(ikey::IndivKey, geno::GPGeno)
    Pheno(ikey, Expr(geno))
end

# Definitions for ConstantGPPheno
mutable struct ConstantTerminalFunctor <: TerminalFunctor
    val::Float64
end

function(terminal::ConstantTerminalFunctor)()
    terminal.val
end

struct ConstantGPPheno <: Phenotype
    ikey::IndivKey
    expr::Expr
    x::ConstantTerminalFunctor
end


Base.@kwdef struct ConstantGPPhenoCfg <: PhenoConfig
    val::Float64 = 0.0
end

function(cfg::ConstantGPPhenoCfg)(ikey::IndivKey, geno::GPGeno)
    e = Expr(geno)
    if isa(e, Symbol) || isa(e, Real)
        return Pheno(ikey, e)
    end
    x = ConstantTerminalFunctor(cfg.val)
    e = symcompile(e, Dict(:x => x), false)
    ConstantGPPheno(ikey, e, x)
    #Pheno(ikey, Expr(geno))
end


# Definitions for TapeReaderGPPheno
mutable struct TapeReaderTerminalFunctor{T <: Real} <: TerminalFunctor
    head::Int
    tape::Vector{T}
end

function TapeReaderTerminalFunctor()
    TapeReaderTerminalFunctor(1, [0.0])
end

function TapeReaderTerminalFunctor(tape::Vector{<:Real})
    TapeReaderTerminalFunctor(length(tape), tape)
end

# Read the current value from the tape, and move the head back one position.
# If the head is at the beginning of the tape, move it to the end.
# (We use a circular tape.)
function(r::TapeReaderTerminalFunctor)()
    val = r.tape[r.head]
    r.head = r.head == 1 ? Base.length(r.tape) : r.head - 1
    val
end

struct TapeReaderGPPheno <: Phenotype
    ikey::IndivKey
    expr::Expr
    reader::TapeReaderTerminalFunctor
end

Base.@kwdef struct TapeReaderGPPhenoCfg <: PhenoConfig
end

function set_head!(pheno::TapeReaderGPPheno, head::Int)
    pheno.reader.head = head
end

function reset!(pheno::TapeReaderGPPheno)
    tape = pheno.reader.tape
    empty!(tape)
    push!(tape, 0.0)
    set_head!(pheno, 1)
end


function add_value!(pheno::TapeReaderGPPheno, val::Float64)
    push!(pheno.reader.tape, val)
    set_head!(pheno, length(pheno.reader.tape))
end

function get_tape_copy(pheno::TapeReaderGPPheno)
    copy(pheno.reader.tape)
end

function spin(pheno::TapeReaderGPPheno)
    eval(pheno.expr)
end

function(cfg::TapeReaderGPPhenoCfg)(ikey::IndivKey, geno::GPGeno)
    e = Expr(geno)
    reader = TapeReaderTerminalFunctor()
    # This is the case of a singleton real-vaued terminal
    if isa(e, Real)
        e = Expr(:call, +, e, 0)
    # This is the case of a singleton :read terminal
    elseif isa(e, Symbol)
        e = Expr(:call, reader)
    else
        symcompile!(e, Dict(:read => reader))
    end
    TapeReaderGPPheno(ikey, e, reader)
end