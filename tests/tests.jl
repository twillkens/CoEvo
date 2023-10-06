using Test

@testset "CoEvo" begin

using Random: AbstractRNG
using StableRNGs: StableRNG
include("../src/CoEvo.jl")
using .CoEvo

include("numbers.jl")
include("gp.jl")
include("sym_regress.jl")
include("gnarl/gnarl.jl")
include("disco.jl")
include("cont_pred.jl")
include("fsm/fsm.jl")

end