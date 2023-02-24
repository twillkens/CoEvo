export Key, IndivKey, TestKey

abstract type Key end

struct IndivKey
    spid::Symbol
    iid::UInt32
end

function IndivKey(spid::Symbol, iid::Int)
    IndivKey(spid, UInt32(iid))
end

function IndivKey(spid::String, iid::String)
    IndivKey(Symbol(spid), parse(UInt32, iid))
end

struct TestKey
    oid::Symbol
    ikey::IndivKey
end

function Base.getproperty(key::TestKey, prop::Symbol)
    if prop == :spid
        key.ikey.spid
    elseif prop == :iid
        key.ikey.iid
    else
        getfield(key, prop)
    end
end