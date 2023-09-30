module Abstract 

export Archiver, Individual, Evaluation

using ...Ecosystems.Species.Individuals.Abstract: Individual
using ...Ecosystems.Species.Evaluators.Abstract: Evaluation

abstract type Archiver end

end