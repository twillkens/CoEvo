# export Ingredient, ingredients

# struct Ingredient{P <: PhenoConfig}
#     ikey::IndivKey
#     pcfg::Symbol
# end

# function ingredients(o::Order, sp::Species) 
#     return [Ingredient(indiv.ikey, Symbol(o.phenocfgs[indiv.spid]))
#     for indiv in union(sp.pop, sp.children)]
# end

# function testkey(ingred::Ingredient)
#     ingred.spid, ingred.iid
# end
