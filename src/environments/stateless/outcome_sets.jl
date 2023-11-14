function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype, <:Phenotype}
) where {D <: NumbersGameDomain}
    phenotype_A, phenotype_B = environment.entity_1, environment.entity_2
    output_A, output_B = act!(phenotype_A), act!(phenotype_B)
    outcome_set = measure(environment.domain, output_A, output_B)
    return outcome_set
end

function get_outcome_set(
    environment::StatelessEnvironment{D, <:Phenotype}
) where {D <: SymbolicRegressionDomain}
    subject, test = environment.entity_1, environment.entity_2
    x_value = act!(test)
    y = environment.domain.target_function(x_value[1])
    y_hat = act!(subject, x_value)
    outcome_set = measure(environment.domain, y, y_hat)
    return outcome_set
end
