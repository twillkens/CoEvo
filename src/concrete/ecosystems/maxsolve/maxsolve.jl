module MaxSolve

export MaxSolveEcosystem, MaxSolveEcosystemCreator

import ....Interfaces: create_ecosystem, update_ecosystem!
import ....Interfaces: convert_to_dict, create_from_dict, evaluate
using ....Abstract: Ecosystem, EcosystemCreator, State, AbstractSpecies
using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces: create_species, update_species!
using ....Interfaces
using ...Matrices.Outcome

include("structs.jl")
include("archive.jl")
#include("filter.jl")
#include("evaluate.jl")
#include("evaluation.jl")
#include("sillhouette_kmeans.jl")
#include("cluster.jl")
include("disco/disco.jl")
include("ecosystem.jl")

end
