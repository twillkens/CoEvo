using Random
using ....CoEvo.Abstract: Replacer, Evaluation

# Replaces the population with the children, keeping the best n_elite individuals from the
# population
Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
    sense::Sense = Max()
end

function(r::GenerationalReplacer)(
    ::AbstractRNG, species::Species, evaluations::Vector{<:Evaluation}
)
    pop, children = species.pop, species.children
    if length(children) == 0
        return pop
    end
    elites = sort(pop, by = i -> fitness(i), rev = r.reverse)[1:r.n_elite]
    n_children = length(pop) - r.n_elite
    children = sort(children, by = i -> fitness(i), rev = r.reverse)[1:n_children]
    pop = [elites; children]
    pop

end
