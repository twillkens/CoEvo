export fitness, testscores
export meanfitness


#const fitness_lru = LRU{Veteran, Float64}(maxsize=1000)
function fitness(vet::Veteran)
    length(vet.rdict) == 0 ? 0.0 : sum(values(vet.rdict))
end


#const meanfitness_lru = LRU{Veteran, Float64}(maxsize=1000)
function meanfitness(vet::Veteran)
    length(vet.rdict) == 0 ? 0.0 : mean(values(vet.rdict))
end


# const testscores_lru = LRU{Veteran, SortedDict{String, Float64}}(maxsize=1000)
function testscores(vet::Individual)
    SortedDict(r.tkey => r.score for r in vet.results)
end