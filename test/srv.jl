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