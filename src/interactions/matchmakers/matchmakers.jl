module MatchMakers

export AllvsAllMatchMaker

using ...CoEvo: MatchMaker, Species

Base.@kwdef struct AllvsAllMatchMaker <: MatchMaker 
    type::Symbol = :plus
end

function(mm::AllvsAllMatchMaker)(sp1::Species, sp2::Species)
    if mm.type == :comma
        ids1 = length(s1.children) == 0 ? collect(keys(sp1.pop)) : collect(keys(sp1.children))
        ids2 = length(s2.children) == 0 ? collect(keys(sp2.pop)) : collect(keys(sp2.children))
    elseif mm.type == :plus
        ids1 = [collect(keys(sp1.pop)); collect(keys(sp1.children))]
        ids2 = [collect(keys(sp2.pop)); collect(keys(sp2.children))]
    else
        error("Invalid AllvsAllMatchMaker type: $(mm.type)")
    end
    vec(collect(Iterators.product(ids1, ids2)))
end

end