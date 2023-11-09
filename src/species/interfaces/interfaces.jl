export get_individuals

function get_individuals(species::AbstractSpecies, cohorts::Vector{String})
    individuals = vcat([getfield(species, Symbol(cohort)) for cohort in cohorts]...)
    return individuals
end