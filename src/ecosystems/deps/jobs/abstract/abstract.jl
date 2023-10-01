module Abstract

export Job, JobCreator, Ecosystem

abstract type Job end

abstract type JobCreator end 

using ....Ecosystems.Abstract: Ecosystem
using ....Ecosystems.Species.Individuals.Phenotypes.Abstract: Phenotype
using ....Ecosystems.Interactions.Abstract: Interaction
using ....Ecosystems.Interactions.MatchMakers.Matches.Abstract: Match

end