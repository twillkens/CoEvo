export Recipe, makerecipes

@auto_hash_equals struct Recipe
    oid::Symbol
    ikeys::Tuple{Vararg{IndivKey}}
end

function makerecipes(orders::Set{<:Order}, allsp::Dict{Symbol, <:Species})
    [recipe for recipe in order(allsp) for order in orders]
end