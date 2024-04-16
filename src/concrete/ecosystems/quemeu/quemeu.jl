module QueMEU

export QueMEUEcosystem, QueMEUEcosystemCreator

import ....Interfaces: create_ecosystem, update_ecosystem!
import ....Interfaces: convert_to_dict, create_from_dict, evaluate
using ....Abstract: Ecosystem, EcosystemCreator, State, AbstractSpecies
using ....Abstract
using ....Utilities: find_by_id
using ....Interfaces: create_species, update_species!
using ....Interfaces
using ...Matrices.Outcome

include("evaluation.jl")
include("ecosystem.jl")
include("clustering/clustering.jl")

end
