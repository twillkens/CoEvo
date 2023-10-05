module Tape

export TapeEnvironment, TapeEnvironmentCreator, TapeMethods

include("structs.jl")
using .Structs: TapeEnvironment, TapeEnvironmentCreator

include("methods/methods.jl")
using .TapeMethods: TapeMethods

end