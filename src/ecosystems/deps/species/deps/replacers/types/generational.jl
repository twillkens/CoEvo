using Random: AbstractRNG
using DataStructures: OrderedDict
using .....CoEvo.Abstract: Replacer, Evaluation, Criterion
using .....CoEvo.Utilities.Criteria: Maximize
using .....CoEvo.Ecosystems.Species.Evaluations.ScalarFitness: ScalarFitnessEvaluation
using .....CoEvo.Ecosystems.Species.Evaluations: sort_indiv_evals

"""
    GenerationalReplacer

A replacer strategy that retains the top `n_elite` individuals from the current 
population when transitioning to the next generation.

# Fields
- `n_elite::Int`: Number of elite individuals to retain from the current population.
                  Defaults to 0, meaning no individuals are retained.
- `sort_criterion::Criterion`: A criterion to determine which individuals are considered 
                               'best'. Defaults to `Maximize()`.
"""
Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
    sort_criterion::Criterion = Maximize()
end

"""
    (r::GenerationalReplacer)(::AbstractRNG, pop_evals, children_evals)

Replace the current population with the new generation (children) while retaining 
the top `n_elite` individuals from the current population.

# Arguments
- `pop_evals::OrderedDict{<:Individual, <:Evaluation}`: An ordered dictionary of the current 
                                                        population's individuals and their evaluations.
- `children_evals::OrderedDict{<:Individual, <:Evaluation}`: An ordered dictionary of the children 
                                                              (next generation) individuals and their evaluations.

# Returns
- `OrderedDict{<:Individual, <:Evaluation}`: A new ordered dictionary representing the 
                                            combined population after replacement.
"""
function(replacer::GenerationalReplacer)(
    ::AbstractRNG, 
    pop_evals::OrderedDict{<:Individual, <:Evaluation}, 
    children_evals::OrderedDict{<:Individual, <:Evaluation}
)
    if isempty(children_evals)
        return pop_evals
    end

    elites = collect(pop_evals)[1:replacer.n_elite]
    n_children = length(pop_evals) - replacer.n_elite
    selected_children = collect(children_evals)[1:n_children]

    new_pop_evals = OrderedDict([elites; selected_children])
    new_pop_evals = sort_indiv_evals(replacer.sort_criterion, new_pop_evals)
    return new_pop_evals
end
