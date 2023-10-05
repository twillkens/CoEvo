module NumbersGame

using .....Environments.Concrete.Stateless: StatelessEnvironment
using ......Domains.Concrete: NumbersGameDomain
using ......Domains.Interfaces: measure
using .......Species.Phenotypes.Abstract: Phenotype
using .......Species.Phenotypes.Interfaces: act!

import .....Environments.Interfaces: get_outcome_set

function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype}) where {D <: NumbersGameDomain}
    phenotype_A, phenotype_B = environment.phenotypes
    output_A, output_B = act!(phenotype_A), act!(phenotype_B)
    outcome_set = measure(environment.domain, output_A, output_B)
    return outcome_set
end

end