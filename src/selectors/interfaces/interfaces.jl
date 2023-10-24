export select

function select(
    selector::Selector,
    ::AbstractRNG, 
    new_population::Vector{Individual},
    evaluation::Evaluation
)::Vector{Individual}
    throw(ErrorException(
        "Selector $selector not implemented for $evaluation")
    )
end