export select

using ..Abstract

function select(
    selector::Selector, new_population::Vector{Individual}, evaluation::Evaluation, state::State
)
    selector = typeof(selector)
    new_population = typeof(new_population)
    evaluation = typeof(evaluation)
    state = typeof(state)
    error("select not implemented for $selector, $new_population, $evaluation, $state")
end