export SamplerOrder, SamplerMixOrder


Base.@kwdef struct SamplerMixOrder{D <: Domain, P <: PhenoConfig} <: PairOrder
    domain::D
    outcome::Type{<:Outcome}
    poproles::Dict{String, PopRole{P}}
    subjects_key::String
    tests_key::String
    n_samples::Int
    rng::AbstractRNG
end

function(o::SamplerMixOrder)(pops::Set{GenoPop})
    popdict = Dict{String, Population}(pops)
    subjects = popdict[o.subjects_key]
    subjects_poprole = o.poproles[o.subjects_key]
    tests = popdict[o.tests_key]
    tests_poprole = o.poproles[o.tests_key]
    recipes = Set{Recipe}()
    i = 1
    for subject in subjects.genos
        subject_entityrole = EntityRole(subject, subjects_poprole)
        for test in sample(o.rng, collect(tests.genos), o.n_samples, replace=false)
            test_entityrole = EntityRole(test, tests_poprole)
            entityroles = Set([subject_entityrole, test_entityrole])
            recipe = MixRecipe(i, o, entityroles)
            push!(recipes, recipe)
            i += 1
        end
    end
    recipes
end

Base.@kwdef struct SamplerOrder{D <: Domain, S <: PhenoConfig, T <: PhenoConfig} <: PairOrder
    domain::D
    outcome::Type{<:Outcome}
    subjects_key::String
    subjects_cfg::S
    tests_key::String
    tests_cfg::T
    n_samples::Int
    rng::AbstractRNG
end

function(o::SamplerOrder)(subjects::GenoPop, tests::GenoPop)
    recipes = Set{Recipe}()
    i = 1
    for subject in subjects.genos
        for test in sample(o.rng, collect(tests.genos), o.n_samples, replace=true)
            recipe = PairRecipe(i, o, subject, test)
            push!(recipes, recipe)
            i += 1
        end
    end
    recipes
end