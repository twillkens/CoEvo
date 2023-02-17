export SpawnCounter
export gid!, iid!, gids!, iids!

mutable struct SpawnCounter
    gid::UInt32
    iid::UInt32
    function SpawnCounter()
        new(1, 1)
    end
end

function gid!(sc::SpawnCounter)
    gid = sc.gid
    sc.gid += 1
    gid
end

function iid!(sc::SpawnCounter)
    iid = sc.iid
    sc.iid += 1
    iid
end

function gids!(sc::SpawnCounter, n::Int)
    [gid!(sc) for _ in 1:n]
end

function iids!(sc::SpawnCounter, n::Int)
    [iid!(sc) for _ in 1:n]
end

# function Base.show(io::IO, i::UInt16)
#     print(io, Int(i))
# end
# 
# function Base.show(io::IO, i::UInt32)
#     print(io, Int(i))
# end
# 
# function Base.show(io::IO, i::UInt64)
#     print(io, Int(i))
# end