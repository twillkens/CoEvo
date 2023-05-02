
function gaussian(σ::Real = 1.0)
    function mutation(recombinant::T;
                      rng::AbstractRNG=default_rng()
                     ) where {T <: AbstractVector}
        d = length(recombinant)
        recombinant .+= σ.*randn(rng, d)
        return recombinant
    end
    return mutation
end

function swap2(recombinant::T; rng::AbstractRNG=default_rng()) where {T <: AbstractVector}
    l = length(recombinant)
    from, to = randseg(rng, l)
    swap!(recombinant, from, to)
    return recombinant
end

"""
    scramble(recombinant)

Returns an in-place mutated individual with elements, on a random arbitrary length segment of the genome, been scrambled.
"""
function scramble(recombinant::T; rng::AbstractRNG=default_rng()) where {T <: AbstractVector}
    l = length(recombinant)
    from, to = randseg(rng, l)
    diff = to - from + 1
    if diff > 1
        patch = recombinant[from:to]
        idx = randperm(rng, diff)
        for i in 1:diff
            recombinant[from+i-1] = patch[idx[i]]
        end
    end
    return recombinant
end

"""
    shifting(recombinant)

Returns an in-place mutated individual with a random arbitrary length segment of the genome been shifted to an arbitrary position.
"""
function shifting(recombinant::T; rng::AbstractRNG=default_rng()) where {T <: AbstractVector}
    l = length(recombinant)
    from, to, where = sort(rand(rng, 1:l, 3))
    patch = recombinant[from:to]
    diff = where - to
    if diff > 0
        # move values after tail of patch to the patch head position
        for i in 1:diff
            recombinant[from+i-1] = recombinant[to+i]
        end
        # place patch values in order
        start = from + diff
        for i in eachindex(patch)
            recombinant[start+i-1] = patch[i]
        end
    end
    return recombinant
end
