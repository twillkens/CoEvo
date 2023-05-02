mutable struct FullTapeException <: Exception
end

function make_readtape(tape::Vector{Float64}) 
    i::Int = 1
    function read()
        val = tape[i]
        i = i == Base.length(tape) ? 1 : i + 1
        return val
    end
    read
end

function make_writetape(tape::Vector{Float64}, maxlen::Int=10) 
    function write(val::Float64)
        push!(tape, val)
        length(tape) == maxlen ? throw(FullTapeException()) : val
    end
    write
end

function make_pushpop(stack::Vector{Float64}, read::Function) 
    function pushstack(val::Float64)
        push!(stack, val)
        return val
    end
    function popstack()
        isempty(stack) ? read() : pop!(stack)
    end
    pushstack, popstack
end

function reset_tapes(agent::GPAgent)
    agent.otape = Float64[]
    agent.stack1, agent.stack2 = Float64[], Float64[]
end

function prep_agent(agent::GPAgent, other::GPAgent, game::GeoPredGame)
    reset_tapes(agent)
    read = make_readtape(other.tape)
    write = make_writetape(agent.otape, game.maxlen)
    push1, pop1 = make_pushpop(stack1, read)
    push2, pop2 = make_pushpop(stack2, read)
    sdict = Dict{Symbol, Function}(:read => read, :write => write,
                                   :push1 => push1, :pop1 => pop1,
                                   :push2 => push2, :pop2 => pop2)
    sdict
end

function simulate!(game::GeoPredGame, a1::GPAgent, a2::GPAgent)
    sdict1 = prep_agent(a1, a2, game)
    sdict2 = prep_agent(a2, a1, game)

    while true
        try
            evaluate(a1.expr, sdict1)
        catch FullTapeException
            break
        end
    end
    while true
        try
            evaluate(a2.expr, sdict2)
        catch FullTapeException
            break
        end
    end
    a1, a2
end
