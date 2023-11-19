using CoEvo
using CoEvo.Names

include("fibonacci.jl")
include("environment.jl")
include("observer.jl")
include("prune.jl")

function main_fibonacci()
    environment = create_fibonacci_environment(8)
    observer = FunctionGraphModesObserver()
    while is_active(environment)
        observe!(observer, environment)
        step!(environment)
    end
    return observer
end

function main_simple()
    environment = create_test_batch_environment()
    observer = FunctionGraphModesObserver()
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    return environment, observer
end

function main_prune()
    current_genotype = create_simple_function_graph_genotype()
    environment = create_test_batch_environment(current_genotype)
    observer = FunctionGraphModesObserver()
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    current_error = sum(environment.errors)
    println("Current genotype: ", current_genotype)
    println("Current error: ", current_error)
    current_observation = create_observation(observer)
    hidden_node_ids = sort(deepcopy(current_genotype.hidden_node_ids), rev=true)
    while !isempty(hidden_node_ids)
        hidden_node_id = popfirst!(hidden_node_ids)
        node_to_remove_mean = current_observation.node_means[hidden_node_id]
        println("Removing node ", hidden_node_id, " with mean ", node_to_remove_mean)
        pruned_genotype = remove_subtree_and_redirect(
            current_genotype, hidden_node_id, 0, Float64(node_to_remove_mean)
        )
        println("Pruned genotype: ", pruned_genotype)
        environment = create_test_batch_environment(pruned_genotype)
        observer = FunctionGraphModesObserver()
        while is_active(environment)
            step!(environment)
            observe!(observer, environment)
        end
        pruned_observation = create_observation(observer)
        pruned_error = sum(environment.errors)
        println("Pruned error: ", pruned_error)
        if pruned_error <= current_error
            current_genotype = pruned_genotype
            current_observation = pruned_observation
            current_error = pruned_error
            hidden_node_ids = filter(x -> x ∈ current_genotype.hidden_node_ids, hidden_node_ids)
            println("New current genotype: ", current_genotype)
            println("New current error: ", current_error)
        end
    end
    return current_genotype, current_error
end

function get_input_ids(node::FunctionGraphNode)
    ids = [connection.input_node_id for connection in node.input_connections]
    return ids
end

function get_input_ids(nodes::Vector{FunctionGraphNode})
    ids = Int[]
    for node in nodes
        append!(ids, get_input_ids(node))
    end
    return ids
end

function main_prune()
    current_genotype = create_simple_function_graph_genotype()
    environment = create_test_batch_environment(current_genotype)
    observer = FunctionGraphModesObserver()
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    current_error = sum(environment.errors)
    println("Current genotype: ", current_genotype)
    println("Current error: ", current_error)
    current_observation = create_observation(observer)
    output_nodes = [current_genotype.nodes[id] for id in current_genotype.output_node_ids]
    to_visit = sort(get_input_ids(output_nodes), rev = true)
    already_visited = Int[]
    while !isempty(to_visit)
        println("-----------------------")
        println("To visit: ", to_visit)
        pruned_node_id = popfirst!(to_visit)
        println("Visiting node ", pruned_node_id)
        push!(already_visited, pruned_node_id)
        inputs_to_pruned_node = get_input_ids(current_genotype.nodes[pruned_node_id])
        for input_id in inputs_to_pruned_node
            if input_id ∉ (
                already_visited ∪ 
                current_genotype.input_node_ids ∪ 
                current_genotype.bias_node_ids
            )
                push!(to_visit, input_id)
            end
        end
        sort!(to_visit, rev = true)

        pruned_node_mean = current_observation.node_means[pruned_node_id]
        println("Pruned node ", pruned_node_id, " with mean ", pruned_node_mean)
        pruned_genotype = remove_node_and_redirect(
            current_genotype, pruned_node_id, 0, Float64(pruned_node_mean)
        )
        println("Pruned genotype: ", pruned_genotype)
        environment = create_test_batch_environment(pruned_genotype)
        observer = FunctionGraphModesObserver()
        while is_active(environment)
            step!(environment)
            observe!(observer, environment)
        end
        pruned_observation = create_observation(observer)
        pruned_error = sum(environment.errors)
        println("Pruned error: ", pruned_error)
        if pruned_error <= current_error
            current_genotype = minimize(pruned_genotype)
            current_observation = pruned_observation
            current_error = pruned_error
            to_visit = filter(x -> x ∈ current_genotype.hidden_node_ids, to_visit)
            println("New current genotype: ", current_genotype)
            println("New current error: ", current_error)
            println("New observation means: ", current_observation.node_means)
        end
    end
    return current_genotype, current_error
end



function initialize_pruning()
    genotype = create_simple_function_graph_genotype()
    environment = create_test_batch_environment(genotype)
    observer = FunctionGraphModesObserver()
    return genotype, environment, observer
end

function evaluate_genotype(environment, observer)
    while is_active(environment)
        step!(environment)
        observe!(observer, environment)
    end
    return sum(environment.errors)
end

function prune_node(genotype, node_id, bias_node_id, weight, observer)
    pruned_genotype = remove_node_and_redirect(genotype, node_id, bias_node_id, weight)
    environment = create_test_batch_environment(pruned_genotype)
    new_observer = FunctionGraphModesObserver()
    error = evaluate_genotype(environment, new_observer)
    observation = create_observation(new_observer)
    return pruned_genotype, error, observation
end

function update_to_visit(to_visit, already_visited, current_genotype, node_id)
    inputs = get_input_ids(current_genotype.nodes[node_id])
    forbidden = already_visited ∪ current_genotype.input_node_ids ∪ current_genotype.bias_node_ids ∪ [node_id]
    ids = [id for id in inputs if id ∉ forbidden]
    ids = sort(ids, rev = true)
    ids
end


function main_prune()
    current_genotype, environment, observer = initialize_pruning()
    current_error = evaluate_genotype(environment, observer)
    println("Current genotype: ", current_genotype)
    println("Current error: ", current_error)
    current_observation = create_observation(observer)
    output_nodes = [current_genotype.nodes[id] for id in current_genotype.output_node_ids]
    to_visit = sort(get_input_ids(output_nodes), rev = true)
    already_visited = Int[]

    while !isempty(to_visit)
        println("-----------------------")
        node_id = popfirst!(to_visit)
        already_visited = [already_visited..., node_id]
        to_visit = update_to_visit(to_visit, already_visited, current_genotype, node_id)

        pruned_mean = current_observation.node_means[node_id]
        pruned_genotype, pruned_error, pruned_observation = prune_node(
            current_genotype, node_id, 0, Float64(pruned_mean), observer
        )
        if pruned_error <= current_error
            current_genotype, current_error, current_observation = pruned_genotype, pruned_error, pruned_observation
            to_visit = filter(x -> x ∈ current_genotype.hidden_node_ids, to_visit)
            println("Updated genotype and error.")
        end
    end
    return current_genotype, current_error
end