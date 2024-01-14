
const SELECTORS = Dict(
    "roulette" => FitnessProportionateSelector(n_parents = 1),
    "tournament" => TournamentSelector(n_parents = 1, tournament_size = 3),
)