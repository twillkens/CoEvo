using Test
#include("../../src/CoEvo.jl")
using .CoEvo

@testset "Simulate" begin

phenotype_creator = DefaultPhenotypeCreator()
@testset "newsimple" begin
        
    # Construct FiniteStateMachinePhenotype for fsm1
    ones = Set(["A1"])
    zeros = Set(["A0"])
    start = "A0"
    start_bit = start in ones
    links = Dict(
        ("A0", false)  => ("A0"),
        ("A0", true)  => ("A1"),
        ("A1", false)  => ("A0"),
        ("A1", true)  => ("A1"),
    )
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    fsm1 = create_phenotype(phenotype_creator, genotype)

    # Construct FiniteStateMachinePhenotype for fsm2
    ones = Set(["B1"])
    zeros = Set(["B0"])
    start = "B0"
    start_bit = start in ones
    links = Dict(
        ("B0", false)  => ("B1"),
        ("B0", true)   => ("B0"),
        ("B1", false)  => ("B1"),
        ("B1", true)   => ("B0")
    )
    genotype = FiniteStateMachineGenotype(start, ones, zeros, links)
    fsm2 = create_phenotype(phenotype_creator, genotype)

    domain = LinguisticPredictionGameDomain(:CooperativeMatching)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    environment = create_environment(environment_creator, [fsm1, fsm2])
    while is_active(environment)
        next!(environment)
    end
    outcome_set = get_outcome_set(environment)
    @test outcome_set == [0.5, 0.5]
    @test environment.states1 == ["A0", "A0", "A1", "A1", "A0"]
    @test environment.states2 == ["B0", "B1", "B1", "B0", "B0"]
    @test environment.bits1 == [0, 0, 1, 1, 0]
    @test environment.bits2 == [0, 1, 1, 0, 0]
    @test environment.loop_start == 1
    @test environment.timestep == 5
end

@testset "newcoop1" begin
        
    # Construct FiniteStateMachinePhenotype for fsm1
    ones = Set(["A1"])
    zeros = Set(["A0"])
    start = "A0"
    start_bit = start in ones
    links = Dict(
        ("A0", false)  => ("A1", "A1" in ones),
        ("A0", true)   => ("A1", "A1" in ones),
        ("A1", false)  => ("A1", "A1" in ones),
        ("A1", true)   => ("A0", "A0" in ones)
    )
    fsm1 = FiniteStateMachinePhenotype((start, start_bit), links)

    # Construct FiniteStateMachinePhenotype for fsm2
    ones = Set(["B1"])
    zeros = Set(["B0"])
    start = "B0"
    start_bit = start in ones
    links = Dict(
        ("B0", false)  => ("B0", "B0" in ones),
        ("B0", true)   => ("B1", "B1" in ones),
        ("B1", false)  => ("B0", "B0" in ones),
        ("B1", true)   => ("B1", "B1" in ones)
    )
    fsm2 = FiniteStateMachinePhenotype((start, start_bit), links)

    domain = LinguisticPredictionGameDomain(:CooperativeMatching)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    environment = create_environment(environment_creator, [fsm1, fsm2])
    while is_active(environment)
        next!(environment)
    end
    outcome_set = get_outcome_set(environment)
    
    # Adjusted the tests to fit the new structure. 
    @test outcome_set ≈ [1/3, 1/3]
    @test environment.states1 == ["A0", "A1", "A1", "A0", "A1"]
    @test environment.states2 == ["B0", "B0", "B1", "B1", "B0"]
    @test environment.bits1 == [0, 1, 1, 0, 1]
    @test environment.bits2 == [0, 0, 1, 1, 0]
    @test environment.loop_start == 2  # This assumes loop starts at 3rd state; adjust as necessary.
    @test environment.timestep == 5
end

@testset "newcomp1" begin
        
    # Construct FiniteStateMachinePhenotype for fsm1
    ones = Set(["A1"])
    zeros = Set(["A0"])
    start = "A0"
    start_bit = start in ones
    links = Dict(
        ("A0", false)  => ("A1", "A1" in ones),
        ("A0", true)   => ("A1", "A1" in ones),
        ("A1", false)  => ("A1", "A1" in ones),
        ("A1", true)   => ("A0", "A0" in ones)
    )
    fsm1 = FiniteStateMachinePhenotype((start, start_bit), links)

    # Construct FiniteStateMachinePhenotype for fsm2
    ones = Set(["B1"])
    zeros = Set(["B0"])
    start = "B0"
    start_bit = start in ones
    links = Dict(
        ("B0", false)  => ("B0", "B0" in ones),
        ("B0", true)   => ("B1", "B1" in ones),
        ("B1", false)  => ("B0", "B0" in ones),
        ("B1", true)   => ("B1", "B1" in ones)
    )
    fsm2 = FiniteStateMachinePhenotype((start, start_bit), links)

    domain = LinguisticPredictionGameDomain(:Competitive)  # Updated to reflect Mismatch Competition
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    environment = create_environment(environment_creator, [fsm1, fsm2])
    while is_active(environment)
        next!(environment)
    end
    outcome_set = get_outcome_set(environment)
    
    # Adjusted the tests to fit the new structure. 
    @test outcome_set ≈ [1/3, 2/3]
    @test environment.states1 == ["A0", "A1", "A1", "A0", "A1"]
    @test environment.states2 == ["B0", "B0", "B1", "B1", "B0"]
    @test environment.bits1 == [0, 1, 1, 0, 1]
    @test environment.bits2 == [0, 0, 1, 1, 0]
    @test environment.loop_start == 2  # This assumes loop starts at 3rd state; adjust as necessary.
    @test environment.timestep == 5
end

@testset "newcoop2" begin
        
    # Construct FiniteStateMachinePhenotype for fsm1
    ones = Set(["b", "c"])
    zeros = Set(["a"])
    start = "a"
    start_bit = start in ones
    links = Dict(
        ("a", false)  => ("a", "a" in ones),
        ("a", true)   => ("b", "b" in ones),
        ("b", false)  => ("c", "c" in ones),
        ("b", true)   => ("b", "b" in ones),
        ("c", false)  => ("c", "c" in ones),
        ("c", true)   => ("b", "b" in ones)
    )
    fsm1 = FiniteStateMachinePhenotype((start, start_bit), links)

    # Construct FiniteStateMachinePhenotype for fsm2
    ones = Set(["a", "c"])
    zeros = Set(["b"])
    start = "a"
    start_bit = start in ones
    links = Dict(
        ("a", false)  => ("a", "a" in ones),
        ("a", true)   => ("b", "b" in ones),
        ("b", false)  => ("b", "b" in ones),
        ("b", true)   => ("c", "c" in ones),
        ("c", false)  => ("a", "a" in ones),
        ("c", true)   => ("a", "a" in ones)
    )
    fsm2 = FiniteStateMachinePhenotype((start, start_bit), links)

    domain = LinguisticPredictionGameDomain(:CooperativeMatching)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    environment = create_environment(environment_creator, [fsm1, fsm2])
    while is_active(environment)
        next!(environment)
    end
    outcome_set = get_outcome_set(environment)
    
    # Adjusted the tests to fit the new structure. 
    @test outcome_set ≈ [2/3, 2/3]
    @test environment.states1 == ["a", "b", "b", "c", "b"]
    @test environment.states2 == ["a", "a", "b", "c", "a"]
    @test environment.bits1 == [0, 1, 1, 1, 1]
    @test environment.bits2 == [1, 1, 0, 1, 1]
    @test environment.loop_start == 2  # This assumes loop starts at 3rd state; adjust as necessary.
    @test environment.timestep == 5
end

@testset "newcomp2" begin
        
    # Construct FiniteStateMachinePhenotype for fsm1
    ones = Set(["b", "c"])
    zeros = Set(["a"])
    start = "a"
    start_bit = start in ones
    links = Dict(
        ("a", false)  => ("a", "a" in ones),
        ("a", true)   => ("b", "b" in ones),
        ("b", false)  => ("c", "c" in ones),
        ("b", true)   => ("b", "b" in ones),
        ("c", false)  => ("c", "c" in ones),
        ("c", true)   => ("b", "b" in ones)
    )
    fsm1 = FiniteStateMachinePhenotype((start, start_bit), links)

    # Construct FiniteStateMachinePhenotype for fsm2
    ones = Set(["a", "c"])
    zeros = Set(["b"])
    start = "a"
    start_bit = start in ones
    links = Dict(
        ("a", false)  => ("a", "a" in ones),
        ("a", true)   => ("b", "b" in ones),
        ("b", false)  => ("b", "b" in ones),
        ("b", true)   => ("c", "c" in ones),
        ("c", false)  => ("a", "a" in ones),
        ("c", true)   => ("a", "a" in ones)
    )
    fsm2 = FiniteStateMachinePhenotype((start, start_bit), links)

    domain = LinguisticPredictionGameDomain(:Competitive)
    environment_creator = LinguisticPredictionGameEnvironmentCreator(domain)
    environment = create_environment(environment_creator, [fsm1, fsm2])
    while is_active(environment)
        next!(environment)
    end
    outcome_set = get_outcome_set(environment)
    
    # Adjusted the tests to fit the new structure. 
    @test outcome_set ≈ [2/3, 1/3]
    @test environment.states1 == ["a", "b", "b", "c", "b"]
    @test environment.states2 == ["a", "a", "b", "c", "a"]
    @test environment.bits1 == [0, 1, 1, 1, 1]
    @test environment.bits2 == [1, 1, 0, 1, 1]
    @test environment.loop_start == 2  # This assumes loop starts at 3rd state; adjust as necessary.
    @test environment.timestep == 5
end


end