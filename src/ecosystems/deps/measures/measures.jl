module Measures

export Abstract, BasicStatisticalMeasureSet

include("abstract/abstract.jl")
using .Abstract: Abstract

#include("types/individual_identity.jl")
#using .IndividualIdentity: IndividualIdentityMeasureSet

include("types/basic_statistical.jl")
using .BasicStatistical: BasicStatisticalMeasureSet 

end