function makegenodict(allsp::Set{<:GSpecies})
    Dict([sp.spkey => Dict([indiv.iid => indiv
        for indiv in union(sp.pop, sp.children)])
        for sp in allsp])
end