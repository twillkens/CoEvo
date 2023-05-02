
mutable struct GPPopulation <: AbstractPopulation
    key::String
    tgp::TreeGP
    indivs::Vector{GPIndiv}
    indiv_num::Int
    innovation_num::Int
    gen::Int
    disco::PopDiscoLog
end


function GPPopulation(tgp::TreeGP)
    indivs = GPIndiv[]
    for i in 1:tgp.n_indiv
        indivkey = join([tgp.key, i], "-")
        parentkey = join([tgp.key, 0], "-")
        genkey = string(i)
        indiv = GPIndiv(indivkey, parentkey, parentkey, genkey, tgp)
        push!(indivs, indiv)
    end
    GPPopulation(tgp.key, tgp, indivs,
                 tgp.n_indiv + 1, 0, 1,
                 PopDiscoLog(0, 0, nothing))
end

"""Tournament selection"""
function gp_tournament(groupSize::Int; select=argmin)
    @assert groupSize > 0 "Group size must be positive"
    function tournamentN(fitness::AbstractVecOrMat{<:Real}, N::Int;
                         rng::AbstractRNG=default_rng())
        selection = fill(0,N)
        sFitness = size(fitness)
        d, nFitness = length(sFitness) == 1 ? (1, sFitness[1]) : sFitness
        tour = randperm(rng, nFitness)
        j = 1
        for i in 1:N
            idxs = tour[j:j+groupSize-1]
            selected = d == 1 ? view(fitness, idxs) : view(fitness, :, idxs)
            winner = select(selected)
            selection[i] = idxs[winner]
            j+=groupSize
            if (j+groupSize) >= nFitness && i < N
                tour = randperm(rng, nFitness)
                j = 1
            end
        end
        return selection
    end
    return tournamentN
end