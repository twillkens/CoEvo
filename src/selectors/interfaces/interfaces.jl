export select

using ..Evaluators.AdaptiveArchive: AdaptiveArchiveEvaluation

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

function select(
    selector::Selector,
    random_number_generator::AbstractRNG, 
    new_population::Vector{Individual},
    evaluation::AdaptiveArchiveEvaluation
)::Vector{Individual}
    return select(
        selector, 
        random_number_generator, 
        new_population, 
        evaluation.full_evaluation
    )
end