export AllvsAllOrder, AllvsAllMixOrder, PopRole


Base.@kwdef struct AllvsAllMixOrder{D <: Domain, P <: PhenoConfig} <: Order
    domain::D
    outcome::Type{<:Outcome}
    poproles::Dict{String, PopRole{P}}
end

function getroles(o::Order, pop::GenoPop) 
    if pop.key ∉ keys(o.poproles)
        throw(Error("Popkey not in poproles"))
    end
    poprole = o.poproles[pop.key]
    return [EntityRole(geno, poprole) for geno in pop.genos]
end

function(o::AllvsAllMixOrder)(pops::Set{ParetoPop})
    if length(pops) != 2
        throw(Error("pareto coevolution only works for 2-way interacitons currently"))
    end
    pop1, pop2 = pops
    p1, c1 = pop1.parents, pop1.children
    p2, c2 = pop2.parents, pop2.children
    parents1 = getroles(o, p1)
    parents2 = getroles(o, p2)
    children1 = getroles(o, c1)
    children2 = getroles(o, c2)
    p1c2 = unique(Set, Iterators.filter(allunique,
                   Iterators.product([parents1, children2])))
    p2c1 = unique(Set, Iterators.filter(allunique,
                   Iterators.product([parents2, children1])))
    c1c2 = unique(Set, Iterators.filter(allunique,
                   Iterators.product([children1, children2])))
    entityrole_sets = union(p1c2, p2c1, c1c2)
    Set([MixRecipe(mixn, o, Set(entity_roleset))
        for (mixn, entity_roleset) in enumerate(entityrole_sets)])
end

function(o::AllvsAllMixOrder)(pops::Set{GenoPop})
    all_entityroles = []
    for pop in pops
        if pop.key ∉ keys(o.poproles)
            continue
        end
        poprole = o.poproles[pop.key]
        entityroles = [EntityRole(geno, poprole) for geno in pop.genos]
        push!(all_entityroles, entityroles)
    end
    entityrole_sets = unique(Set,
                   Iterators.filter(allunique,
                   Iterators.product(all_entityroles...)))
    Set([MixRecipe(mixn, o, Set(entity_roleset))
        for (mixn, entity_roleset) in enumerate(entityrole_sets)])
end

function(o::AllvsAllMixOrder)(pops::Set{ParetoPop})
    if length(pops) != 2
        throw(Error("can have 2 ParetoPops interact currently"))
    end
    subject, tests = collect(pops)
    r1 = get_product(subjects.parents, tests.children)
    r2 = get_product(subjects.children, tests.parents)
    r3 = get_product(subjects.children, tests.children)
    pairs = union(r1, r2, r3)
    Set([PairRecipe(i, o, subject, test) for (i, (subject, test)) in enumerate(pairs)])
end

Base.@kwdef struct AllvsAllOrder{D <: Domain, S <: PhenoConfig, T <: PhenoConfig} <: PairOrder
    domain::D
    outcome::Type{<:Outcome}
    subjects_key::String
    subjects_cfg::S
    tests_key::String
    tests_cfg::T
end

function(o::AllvsAllOrder)(subjects::GenoPop, tests::GenoPop)
    pairs = unique(Set,
                   Iterators.filter(allunique,
                   Iterators.product(subjects.genos, tests.genos)))
    Set([PairRecipe(i, o, subject, test) for (i, (subject, test)) in enumerate(pairs)])
end

function get_product(subjects::Set{<:Genotype}, tests::Set{<:Genotype})
    pairs = unique(Set,
                   Iterators.filter(allunique,
                   Iterators.product(subjects, tests)))
    pairs
end

function(o::AllvsAllOrder)(subjects::ParetoPop, tests::ParetoPop)
    r1 = get_product(subjects.parents, tests.children)
    r2 = get_product(subjects.children, tests.parents)
    r3 = get_product(subjects.children, tests.children)
    pairs = union(r1, r2, r3)
    Set([PairRecipe(i, o, subject, test) for (i, (subject, test)) in enumerate(pairs)])
end