export fitness, testscores
export meanfitness

function fitness(vet::Veteran)
    length(vet.rdict) == 0 ? 0.0 : sum(values(vet.rdict))
end

function meanfitness(vet::Veteran)
    length(vet.rdict) == 0 ? 0.0 : mean(values(vet.rdict))
end

function testscores(vet::Individual)
    SortedDict(r.tkey => r.score for r in vet.results)
end