function simple_tests()
    tests = [BasicTestPhenotype([x], [x + 2.0f0]) for x in 1:10]
    return tests
end

function fibonacci_tests()
    tests = [
        BasicTestPhenotype([1.0], [1.0]),
        BasicTestPhenotype([1.0], [1.0]),
        BasicTestPhenotype([1.0], [2.0]),
        BasicTestPhenotype([1.0], [3.0]),
        BasicTestPhenotype([1.0], [5.0]),
        BasicTestPhenotype([1.0], [8.0]),
        BasicTestPhenotype([1.0], [13.0]),
        BasicTestPhenotype([1.0], [21.0]),
    ]
    return tests
end

function initialize_pruning(do_simple::Bool = true)
    if do_simple
        genotype = create_simple_function_graph_genotype()
        tests = simple_tests()
    else
        genotype = create_fibonacci_function_graph_genotype()
        tests = fibonacci_tests()
    end
    environment = create_test_batch_environment(genotype, tests)
    return genotype, environment, observer
end


function get_tests(configuration::String)
    tests = Dict(
        "simple" => simple_tests(),
        "fibonacci" => fibonacci_tests(),
        "prediction" => [individual.genotype for individual in deserialize("parasites.jls")]
    )
    tests = tests[configuration]
    return tests
end

function get_genotype(configuration::String)
    genotypes = Dict(
        "simple" => create_simple_function_graph_genotype(),
        "fibonacci" => create_fibonacci_function_graph_genotype(),
        "prediction" => deserialize("host.jls").genotype
    )
    genotype = genotypes[configuration]
    return genotype
end


function modes_evaluate(genotype::FunctionGraphGenotype, tests::Vector{BasicTestPhenotype})
    tests = deepcopy(tests)
    environment = create_test_batch_environment(genotype, tests)
    observer = FunctionGraphModesObserver()
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    println(environment.errors)
    error = sum(environment.errors)
    observation = create_observation(observer)
    return error, observation
end


function main_prune_2(configuration::String, maximize_outcome::Bool = false)
    current_genotype = get_genotype(configuration)
    current_genotype = minimize(current_genotype)
    tests = get_tests(configuration)
    current_outcome_sum, current_observation = evaluate_genotype(current_genotype, tests)
    #return current_observation
    println("Current genotype: ", current_genotype)
    println("Current outcome_sum: ", current_outcome_sum)
    println("Current observation medians: ", current_observation.node_medians)
    #output_nodes = [current_genotype.nodes[id] for id in current_genotype.output_node_ids]
    to_visit = sort(current_genotype.hidden_node_ids, rev = true)
    already_visited = Int[]

    while !isempty(to_visit)
        pruned_node_id = popfirst!(to_visit)
        println("-----------------------")
        println("Visiting node ", pruned_node_id)
        println("To visit remaining: ", to_visit)
        push!(already_visited, pruned_node_id)
        #to_visit = update_to_visit(to_visit, already_visited, current_genotype, pruned_node_id)

        pruned_node_median = current_observation.node_medians[pruned_node_id]
        println("Pruned node ", pruned_node_id, " with median ", pruned_node_median)
        pruned_genotype, pruned_outcome_sum, pruned_observation = prune_node(
            current_genotype, pruned_node_id, Float64(pruned_node_median), tests
        )
        println("pruned_outcome_sum: ", pruned_outcome_sum)
        perform_genotype_minimization = maximize_outcome ? 
            pruned_outcome_sum >= current_outcome_sum : 
            pruned_outcome_sum <= current_outcome_sum
        if perform_genotype_minimization
            current_genotype = minimize(pruned_genotype)
            current_outcome_sum = pruned_outcome_sum
            current_observation = pruned_observation
            to_visit = filter(x -> x ∈ current_genotype.hidden_node_ids, to_visit)
            println("New current genotype after minimization: ", current_genotype)
            println("New current outcome_sum: ", current_outcome_sum)
            println("New observation medians: ", current_observation.node_medians)
        end
    end
    return current_genotype, current_outcome_sum
end