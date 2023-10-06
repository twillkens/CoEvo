module Types

export BasicStatisticalMeasurement, GroupStatisticalMeasurement, AllSpeciesMeasurement

include("statistical.jl")
using .Statistical: BasicStatisticalMeasurement, GroupStatisticalMeasurement

include("common.jl")
using .Common: AllSpeciesMeasurement

end