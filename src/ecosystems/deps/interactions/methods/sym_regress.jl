module SymbolicRegression

export get_outcome_set

using ...Environments.Types.Stateless: StatelessEnvironment
using ....Interactions.Domains.Types.SymbolicRegression: SymbolicRegressionDomain
using ....Metrics.Outcomes.Types.Generic: AbsoluteError
using ....Species.Phenotypes.Abstract: Phenotype
using ....Species.Phenotypes.Interfaces: act!

import ....Interactions.Environments.Interfaces: get_outcome_set

function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype}) where {D <: SymbolicRegressionDomain}
    subject, test = environment.phenotypes
    x_value = act!(test)
    subject_y = act!(subject, x_value)
    test_y = environment.domain.target_function(x_value[1])
    absolute_error = abs(test_y - subject_y)
    outcome_set = [absolute_error, 0.0]
    return outcome_set
end

end