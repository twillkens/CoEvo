using Test

@testset "CoEvo" begin

using Random: AbstractRNG
using StableRNGs: StableRNG
include("../src/CoEvo.jl")
using .CoEvo

include("numbers.jl")
include("gp.jl")
include("sym_regress.jl")
include("gnarl.jl")
include("disco.jl")

end