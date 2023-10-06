module Measurements

export Abstract

include("abstract/abstract.jl")
using .Abstract: Abstract

#include("types/individual_identity.jl")
#using .IndividualIdentity: IndividualIdentityMeasureSet

include("types/types.jl")
using .Types

end