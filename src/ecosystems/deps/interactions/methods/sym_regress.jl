module SymbolicRegression

using ....Interactions.Environments.Abstract: Environment, EnvironmentCreator
using ...Environments.Types.Stateless: StatelessEnvironment
using ....Interactions.Domains.Types.NumbersGame: NumbersGameDomain
using ....Metrics.Outcomes.Types.NumbersGame: Control, Sum, Gradient, Focusing, Relativism
using ....Species.Phenotypes.Vectors.Basic: VectorPhenotype
using ....Species.Phenotypes.Interfaces: act

import ....Interactions.Environments.Interfaces: get_outcome_set
import ....Species.Phenotypes.Interfaces: act


function get_outcome_set(
    environment::Environment{D, P}) where {D <: SymbolicRegressionDomain, P}
    x_value = act(environment.phenotypes[2], nothing)
    subject_y = act(environment.phenotypes[1], x_value)
    test_y = environment.domain.func(x_value)
    score = abs(test_y - subject_y)
    outcome_set = [score, 0.0]
    return outcome_set
end



end