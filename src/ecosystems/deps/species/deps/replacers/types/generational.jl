
using Random: AbstractRNG
using DataStructures: OrderedDict
using .....CoEvo.Abstract: Replacer, Evaluation, Criterion
using .....CoEvo.Utilities.Criteria: Maximize
using ..Evaluations: sort_indiv_evals

# Replaces the population with the children, keeping the best n_elite individuals from the
# population
Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
    sort_criterion::Criterion = Maximize()
end

function(r::GenerationalReplacer)(
    ::AbstractRNG, 
    pop_evals::OrderedDict{<:Individual, <:Evaluation}, 
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)
    # If there are no children, just return the population
    if isempty(children_evals)
        return pop_evals
    end

    # Selecting elites and required number of children
    elites = collect(pop_evals)[1:r.n_elite]
    n_children = length(pop_evals) - r.n_elite
    selected_children = collect(children_evals)[1:n_children]

    # Merging elites and selected children
    new_pop_evals = OrderedDict([elites; selected_children])
    new_pop_evals = sort_indiv_evals(r.sort_criterion, new_pop_evals)
    return new_pop_evals
end