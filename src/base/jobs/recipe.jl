export Recipe

struct Recipe{D <: Domain, O <: ObsConfig, I <: Ingredient}
    rid::Int
    domain::D
    obscfg::O
    ingredients::Set{I}
end

function strip(r::Recipe)
    r.domain, r.obscfg, r.ingredients
end

function Base.isequal(r1::Recipe, r2::Recipe)
    strip(r1) == strip(r2)
end

function Base.hash(r::Recipe)
    hash(strip(r))
end

function Recipe(rid::Int, o::Order, ingredients::Set{<:Ingredient})
    Recipe(rid, o.domain, o.obscfg, ingredients)
end