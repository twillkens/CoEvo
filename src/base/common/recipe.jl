export Recipe, getingredkeys, getikeys, TestKey

@auto_hash_equals struct Recipe
    oid::Symbol
    ikeys::Set{IndivKey}
end

# function Recipe(oid::Symbol, args...)
#     Recipe(oid, Set(args))
# end

function getingredkeys(recipe::Recipe)
    Set(IngredientKey(recipe.oid, ikey) for ikey in recipe.ikeys)
end

function getingredkeys(recipes::Set{<:Recipe})
    Set(ingredkey for recipe in recipes for ingredkey in getingredkeys(recipe))
end


function getikeys(recipes::Set{<:Recipe})
    Set(ikey for recipe in recipes for ikey in recipe.ikeys)
end