using Test

@testset "CoEvo" begin

using Random: AbstractRNG
using StableRNGs: StableRNG
#include("../src/CoEvo.jl")
#using .CoEvo
using CoEvo

include("utils/utils.jl")
include("numbers/numbers.jl")
#include("gp/gp.jl")
#include("sym_regress/sym_regress.jl")
#include("gnarl/gnarl.jl")
#include("disco/disco.jl")
#include("cont_pred/cont_pred.jl")
#include("fsm/fsm.jl")
#include("function_graphs/function_graphs.jl")
#include("archivers/archivers.jl")

end