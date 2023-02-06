export fitness, testscores


function fitness(vet::Veteran)
    get!(fitness_lru, vet) do
        sum(r.score for r in vet.results)
    end
end


function testscores(vet::Individual)
    get!(testscores_lru, vet) do
        SortedDict(r.testkey => r.score for r in vet.results)
    end
end