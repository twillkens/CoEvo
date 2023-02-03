export getfitness, gettestscores

const fitness_lru = LRU{Individual, Float64}(maxsize=1000)

function getfitness(indiv::Individual)
    get!(fitness_lru, indiv) do
        sum([o.score for o in values(indiv.outcomes)])
    end
end

const testscores_lru = LRU{Individual, SortedDict{String, Float64}}(maxsize=1000)

function gettestscores(indiv::Individual)
    get!(testscores_lru, indiv) do
        SortedDict([o.testkey => o.score for o in values(indiv.outcomes)])
    end
end