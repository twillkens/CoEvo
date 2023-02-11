using Serialization


abstract type Cfg end

struct SmallCfg <: Cfg
    x::Int
end

struct BigCfg <: Cfg
    x::Int
    y::Int
    z::Int
end

abstract type Ticket end

struct CfgTicket <: Ticket
    cfg::Cfg
    id::Int
    val::Int
end

struct SymTicket <: Ticket
    cfg::Symbol
    id::Int
    val::Int
end

# cfg = Cfg(1, 2, 3)
cfg = SmallCfg(1)

cfg_tickets = (cfg, [CfgTicket(cfg,  id, rand(Int)) for id in 1:1000000])
sym_tickets = (cfg, [SymTicket(:cfg, id, rand(Int)) for id in 1:1000000])

serialize("cfg_tickets.ser", cfg_tickets)
serialize("sym_tickets.ser", sym_tickets)


struct Sucker
    x::Int
    y::Int
end

smartguys = [(1, 2) for i in 1:100]
suckers = [Sucker(1, 2) for i in 1:100]

serialize("smartguys.jls", smartguys)
serialize("suckers.jls", suckers)
smartguys = deserialize("smartguys.jls")
suckers = deserialize("suckers.jls")
println("smartguys: ", smartguys)
println("suckers", suckers)

function testequals(suckers::Set{Pair{T, T}}) where T
    for pair in suckers
        pair[1] != pair[2]
    end
end

function makesmartguys()
    (rand(Int), rand(Int)) => (rand(Int), rand(Int))
end

function makesuckers()
    Sucker(rand(Int), rand(Int)) => Sucker(rand(Int), rand(Int))
end


function testequals()
    @time smartguys = Set(makesmartguys() for i in 1:1000000)
    @time suckers = Set(makesuckers() for i in 1:1000000)
    @time smartguys = Set(makesmartguys() for i in 1:1000000)
    @time suckers = Set(makesuckers() for i in 1:1000000)
    @time smartguys = Set(makesmartguys() for i in 1:1000000)
    @time suckers = Set(makesuckers() for i in 1:1000000)
    @time testequals(smartguys)
    @time testequals(suckers)
    @time testequals(smartguys)
    @time testequals(suckers)
    @time testequals(smartguys)
    @time testequals(suckers)
end

