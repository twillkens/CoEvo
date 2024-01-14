using ...Selectors.FitnessProportionate: FitnessProportionateSelector
using ...Selectors.Tournament: TournamentSelector
using ....Abstract

function create_selector(config::CircleExperimentConfiguration, species_creator::SpeciesCreator)
    if config.selector == "roulette"
        return FitnessProportionateSelector(n_parents = species_creator.n_parents)
    elseif config.selector == "tournament"
        tournament_size = species_creator.n_parents <= 100 ? 3 : 5
        return TournamentSelector(
            n_parents = species_creator.n_parents, tournament_size = tournament_size
        )
    else
        error("Unknown selector: $(config.selector)")
    end
end
