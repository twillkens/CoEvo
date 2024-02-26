using ....Abstract
using ...Individuals.Dodo: DodoIndividual

function promote_explorer!(species::DodoTestSpecies, individual::DodoIndividual)
    individual.age = 0
    individual.temperature = 1
    filter!(ind -> ind.id != individual.id, species.explorers)
    push!(species.hillclimbers, individual)
end

function promote_explorers!(species::DodoTestSpecies, evaluation::Evaluation)
    for id in evaluation.explorer_to_promote_ids
        explorer = species[id]
        promote_explorer!(species, explorer)
    end
end

function promote_child!(species::DodoTestSpecies, individual::DodoIndividual)
    individual.age = 0
    individual.temperature = 1
    hillclimber_ids = [parent.id for parent in species.hillclimbers]
    if !(individual.parent_id in hillclimber_ids)
        error("Error promoting child $(individual.id). Parent with id = $(individual.parent_id) is not a hillclimber")
    end
    filter!(ind -> ind.id != individual.id, species.children)
    push!(species.hillclimbers, individual)
end

function promote_children!(species::DodoTestSpecies, evaluation::Evaluation)
    for id in evaluation.child_to_promote_ids
        child = species[id]
        promote_child!(species, child)
    end
end

function promote_retiree!(species::DodoTestSpecies, individual::DodoIndividual)
    individual.age = 0
    individual.temperature = 1
    filter!(ind -> ind.id != individual.id, species.retirees)
    push!(species.hillclimbers, individual)
end

function promote_retirees!(species::DodoTestSpecies, evaluation::Evaluation)
    for id in evaluation.retiree_to_promote_ids
        retiree = species[id]
        promote_retiree!(species, retiree)
    end
end

function retire_hillclimber!(
    species::DodoTestSpecies, species_creator::DodoTestSpeciesCreator, individual::DodoIndividual
)
    individual.temperature = 1
    individual.age = 0
    if !(individual in species.hillclimbers)
        error("Error retiring hillclimber. Individual with id = $(individual.id) is not a hillclimber")
    end
    filter!(ind -> ind.id != individual.id, species.hillclimbers)
    push!(species.retirees, individual)
    if length(species.retirees) > species_creator.max_retirees
        popfirst!(species.retirees)
    end
end

function retire_hillclimbers!(
    species::DodoTestSpecies, species_creator::DodoTestSpeciesCreator, evaluation::Evaluation)
    for id in evaluation.hillclimber_to_retire_ids
        hillclimber = species[id]
        retire_hillclimber!(species, species_creator, hillclimber)
    end
    for hillclimber in species.hillclimbers
        if hillclimber.age >= species_creator.max_hillclimber_age
            retire_hillclimber!(species, species_creator, hillclimber)
        end
    end
end
