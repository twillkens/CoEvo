export Recipe, getingredkeys, getikeys, TestKey

@auto_hash_equals struct Recipe
    oid::Symbol
    ikeys::Set{IndivKey}
end

# function Recipe(oid::Symbol, args...)
#     Recipe(oid, Set(args))
# end


function getikeys(recipes::Set{<:Recipe})
    Set(ikey for recipe in recipes for ikey in recipe.ikeys)
end