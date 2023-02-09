export Recipe, getingredkeys, getikeys

struct Recipe
    oid::Symbol
    ikeys::Set{IndivKey}
end

function getingredkeys(recipe::Recipe)
    Set(IngredientKey(recipe.oid, ikey) for ikey in recipe.ikeys)
end

function getingredkeys(recipes::Set{<:Recipe})
    union([getingrkeys(recipe) for recipe in recipes]...)
end

function getikeys(recipes::Set{<:Recipe})
    union([recipe.ikeys for recipe in recipes]...)
end