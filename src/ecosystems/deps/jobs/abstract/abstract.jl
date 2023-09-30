module Abstract

export Job, JobCreator, Ecosystem

abstract type Job end

abstract type JobCreator end 

using ....Ecosystems.Abstract: Ecosystem
using ....Ecosystems.Species.Individuals.Phenotypes.Abstract: Phenotype
using ....Ecosystems.Domains.Abstract: Domain
using ....Ecosystems.Domains.MatchMakers.Matches.Abstract: Match

end