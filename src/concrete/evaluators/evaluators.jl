module Evaluators

export Null, ScalarFitness, NSGAII, Disco, Redisco, HillClimber, DodoLearner
export SpreadDodo
export Dodo, DodoTest, NewDodo, Tin

include("null/null.jl")
using .Null: Null

include("scalar_fitness/scalar_fitness.jl")
using .ScalarFitness: ScalarFitness

include("nsga-ii/nsga-ii.jl")
using .NSGAII: NSGAII

include("disco/disco.jl")
using .Disco: Disco

include("redisco/redisco.jl")
using .Redisco: Redisco

include("hillclimber/hillclimber.jl")
using .HillClimber: HillClimber

include("dodo/dodo.jl")
using .Dodo: Dodo

include("dodo_learner/dodo_learner.jl")
using .DodoLearner: DodoLearner

include("dodo_test/dodo_test.jl")
using .DodoTest: DodoTest

include("spread_dodo/spread_dodo.jl")
using .SpreadDodo: SpreadDodo

include("new_dodo/new_dodo.jl")
using .NewDodo: NewDodo

include("tin/tin.jl")
using .Tin: Tin

end
