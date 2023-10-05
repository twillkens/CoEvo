module SymbolicRegression

using .....Environments.Abstract: Environment, EnvironmentCreator
using .....Environments.Concrete.Stateless: StatelessEnvironment
using ......Domains.Concrete: SymbolicRegressionDomain
using ......Domains.Interfaces: measure
using .......Species.Phenotypes.Abstract: Phenotype
using .......Species.Phenotypes.Interfaces: act!

import .....Environments.Interfaces: get_outcome_set


function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype}
) where {D <: SymbolicRegressionDomain}
    subject, test = environment.phenotypes
    x_value = act!(test)
    y = environment.domain.target_function(x_value[1])
    y_hat = act!(subject, x_value)
    outcome_set = measure(environment.domain, y, y_hat)
    return outcome_set
end


end