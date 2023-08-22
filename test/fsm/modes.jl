
function(c::CoevConfig)(gen::Int, allsp::Dict{Symbol, <:Species})
    if gen % 100 == 0
        archive!(gen, c, allsp)
        allvets, outcomes = interact(c, allsp)
        nextsp = Dict(
            spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
        )
        nextsp
    else
        archive!(gen, c, allsp)
        allvets, outcomes = interact(c, allsp)
        nextsp = Dict(
            spawner.spid => spawner(c.evostate, allvets) for spawner in values(c.spawners)
        )
        nextsp
    end
end

@testset "MODES" begin


@testset "Basic" begin

    
end

end