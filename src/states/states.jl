module States

export Basic
export Global, Evolutionary

import ..SpeciesCreators: create_species

using ..SpeciesCreators: SpeciesCreator

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

#include("global/global.jl")
#using .Global: Global
#
#include("evolutionary/evolutionary.jl")
#using .Evolutionary: Evolutionary

end