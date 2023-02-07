export makerecipes, makegenodict, makephenodict

function makerecipes(orders::Set{<:Order}, allsp::Set{<:Species})
    union([order(allsp) for order in orders]...)
end

function makeallgenos(allsp::Set{<:Species})
    Dict(
        (indiv.spkey, indiv.iid) => genotype(indiv)
        for sp in allsp
        for indiv in union(sp.pop, sp.children)
        
    )
end

function makegenodict(
    allgenos::Dict{Tuple{String, UInt32}, G}, recipes::Set{<:Recipe}) where {G <: Genotype
}
    Dict(ingred => allgenos[(ingred.spkey, ingred.iid)]
    for ingred in union([recipe.ingredients for recipe in recipes]...))
end

function makephenodict(genodict::Dict{I, G}) where {I <: Ingredient, G <: Genotype}
    Dict(ingred => ingred.pcfg(genotype) for (ingred, genotype) in genodict)
end
