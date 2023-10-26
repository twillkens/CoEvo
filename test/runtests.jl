using Test

@testset "CoEvo" begin

include("utils/utils.jl")
include("numbers/numbers.jl")
include("genetic_programs/genetic_programs.jl")
##include("sym_regress/sym_regress.jl")
include("gnarl_networks/gnarl_networks.jl")
include("nsga-ii/nsga-ii.jl")
include("continuous_prediction_game/continuous_prediction_game.jl")
include("finite_state_machines/finite_state_machines.jl")
include("function_graphs/function_graphs.jl")
#include("archivers/archivers.jl")

end