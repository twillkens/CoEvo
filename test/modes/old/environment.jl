Base.@kwdef struct DefaultDomain{M} <: Domain{M} 
    metric::M = NullMetric()
end

function measure(::DefaultDomain, args...)
    return [1.0, 1.0]
end

mutable struct FibonacciEnvironment{D, P1 <: Phenotype} <: Environment{D}
    domain::D
    phenotype::P1
    episode_length::Int
    current_timestep::Int
end

function is_active(environment::FibonacciEnvironment)
    return environment.current_timestep <= environment.episode_length
end

function step!(environment::FibonacciEnvironment)
    input_values = [1.0]
    output_values = act!(environment.phenotype, input_values)
    environment.current_timestep += 1
    return output_values
end

function create_fibonacci_environment(
    episode_length::Int
)
    environment = FibonacciEnvironment(
        DefaultDomain(),
        create_fibonacci_function_graph_phenotype(),
        episode_length,
        1
    )
    return environment
end

struct BasicTestPhenotype
    input::Vector{Float32}
    expected_output::Vector{Float32}
end

mutable struct TestBatchEnvironment{D, P1 <: Phenotype} <: Environment{D}
    domain::D
    phenotype::P1
    tests::Vector{BasicTestPhenotype}
    errors::Vector{Float32}
end

function is_active(environment::TestBatchEnvironment)
    if length(environment.tests) > 0
        return true
    else
        return false
    end
end

function step!(environment::TestBatchEnvironment)
    test = popfirst!(environment.tests)
    output = act!(environment.phenotype, test.input)
    error = sum(abs.(output - test.expected_output))
    push!(environment.errors, error)
end

function create_test_batch_environment(
    phenotype::Phenotype = create_simple_function_graph_phenotype(),
    tests::Vector{BasicTestPhenotype} = [BasicTestPhenotype([x], [x + 2.0f0]) for x in 1:10],
)
    environment = TestBatchEnvironment(
        DefaultDomain(),
        phenotype,
        tests,
        Float32[]
    )
    return environment
end

function create_test_batch_environment(genotype::FunctionGraphGenotype, tests::Vector{BasicTestPhenotype})
    phenotype = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), genotype)
    return create_test_batch_environment(phenotype, tests)
end

function create_fibonacci_env()
    phenotype = create_fibonacci_function_graph_phenotype()
    environment = create_test_batch_environment(phenotype, tests)
    return environment
end
