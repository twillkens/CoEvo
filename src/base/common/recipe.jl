export Recipe, makerecipes

@auto_hash_equals struct Recipe
    oid::Symbol
    ikeys::Tuple{Vararg{IndivKey}}
end

function makerecipes(orders::Dict{Symbol, <:Order}, allsp::Dict{Symbol, <:Species})
    [recipe for order in values(orders) for recipe in order(allsp) ]
end