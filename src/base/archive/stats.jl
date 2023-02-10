export fitness, testscores


const fitness_lru = LRU{Veteran, Float64}(maxsize=1000)
function fitness(vet::Veteran)
    get!(fitness_lru, vet) do
        sum(values(vet.rdict))
    end
end


const testscores_lru = LRU{Veteran, SortedDict{String, Float64}}(maxsize=1000)
function testscores(vet::Individual)
    get!(testscores_lru, vet) do
        SortedDict(r.tkey => r.score for r in vet.results)
    end
end