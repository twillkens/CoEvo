export Key, IndivKey, TestKey

abstract type Key end

struct IndivKey <: Key
    spid::Symbol
    iid::Int
end

function IndivKey(spid::String, iid::String)
    IndivKey(Symbol(spid), parse(Int, iid))
end

struct TestKey <: Key
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