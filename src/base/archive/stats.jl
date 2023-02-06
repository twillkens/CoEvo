export getfitness, gettestscores


function getfitness(indiv::Individual)
    get!(fitness_lru, indiv) do
        sum([o.score for o in values(indiv.outcomes)])
    end
end


function gettestscores(indiv::Individual)
    get!(testscores_lru, indiv) do
        SortedDict([o.testkey => o.score for o in values(indiv.outcomes)])
    end
end