module Basic

export BasicReport, BasicReporter, Methods

include("structs.jl")
using .Structs: BasicReport, BasicReporter

include("methods.jl")
using .Methods: Methods



end