export Recipe

struct Recipe{D <: Domain, O <: ObsConfig, I <: Ingredient}
    rid::UInt64
    domain::D
    obscfg::O
    ingredients::Set{I}
end

function Recipe(domain::Domain, obscfg::ObsConfig, ingredients::Set{<:Ingredient})
    rid = hash((domain, obscfg, ingredients))
    Recipe(rid, domain, obscfg, ingredients)
end

# function strip(r::Recipe)
#     r.domain, r.obscfg, r.ingredients
# end

# function Base.isequal(r1::Recipe, r2::Recipe)
#     strip(r1) == strip(r2)
# end

# function Base.hash(r::Recipe)
#     hash(strip(r))
# end

function Recipe(o::Order, ingredients::Set{<:Ingredient})
    Recipe(o.domain, o.obscfg, ingredients)
end