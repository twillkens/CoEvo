export Ingredient, ingredients

struct Ingredient{P <: PhenoConfig}
    spkey::String
    iid::Int
    pcfg::P
end

function ingredients(o::Order, sp::Species) 
    return [Ingredient(indiv.spkey, indiv.iid, o.phenocfgs[indiv.spkey])
    for indiv in union(sp.pop, sp.children)]
end

function testkey(ingred::Ingredient)
    ingred.spkey, ingred.iid
end
