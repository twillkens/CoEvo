export Substrate, get_n_population, get_n_children, make_individual_creator, make_recombiner
export GnarlNetworkSubstrate, FunctionGraphSubstrate
export make_genotype_creator, make_phenotype_creator, make_mutators
export load_substrate, get_substrate

using ...Names
using ...Genotypes.FiniteStateMachines: FiniteStateMachineGenotypeCreator

abstract type Substrate end

get_n_population(substrate::Substrate) = substrate.n_population

get_n_children(substrate::Substrate) = substrate.n_children

struct FiniteStateMachineSubstrate <: Substrate
    id::String
    n_population::Int
    n_children::Int
end

make_genotype_creator(
    ::FiniteStateMachineSubstrate, ::GameConfiguration
) = FiniteStateMachineGenotypeCreator()

make_individual_creator(::FiniteStateMachineSubstrate) = BasicIndividualCreator()

make_phenotype_creator(::FiniteStateMachineSubstrate) = DefaultPhenotypeCreator()

make_recombiner(::FiniteStateMachineSubstrate) = CloneRecombiner()

make_mutators(::FiniteStateMachineSubstrate) = [FiniteStateMachineMutator()]

struct GnarlNetworkSubstrate <: Substrate
    id::String
    n_population::Int
    n_children::Int
end

function GnarlNetworkSubstrate(;
    id::String = "gnarl_networks", 
    n_population::Int = 10, 
    n_children::Int = 10, 
    kwargs...
)
    substrate = GnarlNetworkSubstrate(id, n_population, n_children)
    return substrate
end

function archive!(substrate::GnarlNetworkSubstrate, file::File)
    base_path = "configuration/substrate"
    file["$base_path/id"] = substrate.id
    file["$base_path/n_population"] = substrate.n_population
    file["$base_path/n_children"] = substrate.n_children
end

function make_genotype_creator(
    ::GnarlNetworkSubstrate, game::GameConfiguration
)
    communication_dimension = game.communication_dimension
    genotype_creator = GnarlNetworkGenotypeCreator(
        n_input_nodes = 1 + communication_dimension, 
        n_output_nodes = 1 + communication_dimension
    )
    return genotype_creator
end

make_individual_creator(::GnarlNetworkSubstrate) = BasicIndividualCreator()

make_phenotype_creator(::GnarlNetworkSubstrate) = DefaultPhenotypeCreator()

make_recombiner(::GnarlNetworkSubstrate) = CloneRecombiner()

make_mutators(::GnarlNetworkSubstrate) = [GnarlNetworkMutator()]

struct FunctionGraphSubstrate <: Substrate 
    id::String
    n_population::Int
    n_children::Int
    n_nodes_per_output::Int
    function_set::String
    mutation::String
    noise_std::String
end

function FunctionGraphSubstrate(;
    id::String = "function_graphs",
    n_population::Int = 10, 
    n_children::Int = 10, 
    n_nodes_per_output::Int = 1, 
    function_set::String = "all",
    mutation::String = "equal_volatile",
    noise_std::String = "moderate",
    kwargs...
)
    substrate = FunctionGraphSubstrate(
        id, n_population, n_children, n_nodes_per_output, function_set, mutation, noise_std
    )
    return substrate
end

function archive!(substrate::FunctionGraphSubstrate, file::File)
    base_path = "configuration/substrate"
    file["$base_path/id"] = substrate.id
    file["$base_path/n_population"] = substrate.n_population
    file["$base_path/n_children"] = substrate.n_children
    file["$base_path/n_nodes_per_output"] = substrate.n_nodes_per_output
    file["$base_path/function_set"] = substrate.function_set
    file["$base_path/mutation"] = substrate.mutation
    file["$base_path/noise_std"] = substrate.noise_std
end

function make_genotype_creator(
    substrate::FunctionGraphSubstrate, game::ContinuousPredictionGameConfiguration
)
    n_nodes_per_output = substrate.n_nodes_per_output
    communication_dimension = game.communication_dimension
    genotype_creator = FunctionGraphGenotypeCreator(
        n_inputs = 2 + communication_dimension, 
        n_bias = 1,
        n_outputs = 1 + communication_dimension,
        n_nodes_per_output = n_nodes_per_output,
    )
    return genotype_creator
end

make_individual_creator(::FunctionGraphSubstrate) = BasicIndividualCreator()

make_phenotype_creator(::FunctionGraphSubstrate) = LinearizedFunctionGraphPhenotypeCreator()

make_recombiner(::FunctionGraphSubstrate) = CloneRecombiner()

FUNCTION_SETS = Dict(
    "all" => [
        :IDENTITY,
        :ADD,
        :SUBTRACT,
        :MULTIPLY,
        :DIVIDE,
        :MAXIMUM,
        :MINIMUM,
        :SINE,
        :COSINE,
        :ARCTANGENT,
        :SIGMOID,
        :TANH,
        :RELU,
        #:IF_LESS_THEN_ELSE,
    ],
    "circle" => [
        :IDENTITY, :ADD, :MULTIPLY, :DIVIDE, :MAXIMUM, :SINE, :COSINE, :ARCTANGENT, #:IF_LESS_THEN_ELSE
    ],
    "simple" => [:ADD, :ARCTANGENT, ]#:IF_LESS_THEN_ELSE]
)
function calculate_probabilities(sum_probability::Float64, percent_more_likely_to_remove::Float64)
    # Converting the percentage to a ratio
    ratio = 1 + percent_more_likely_to_remove / 100

    # Calculating probabilities
    add_function_prob = sum_probability / (1 + ratio)
    rm_function_prob = add_function_prob * ratio

    return (add_function_prob, rm_function_prob)
end

MUTATION_PROBABILITIES = Dict(
    "equal_volatile" => Dict(
        :identity => 0.0,
        :add_function => 0.25,
        :remove_function => 0.25,
        :swap_function => 0.25,
        :redirect_connection => 0.25,
    ),
    "shrink_hypervolatile" => Dict(
        :identity => 0.0,
        :add_function => 1 / 9, 
        :remove_function => 2 / 9,
        :swap_function => 1 / 3,
        :redirect_connection => 1 / 3
    ),
    "shrink_volatile" => Dict(
        :identity => 0.5,
        :add_function => 0.10,
        :remove_function => 0.15,
        :swap_function => 0.125,
        :redirect_connection => 0.125,
    ),
    "shrink_moderate" => Dict(
        :identity => 0.75,
        :add_function => 0.05,
        :remove_function => 0.075,
        :swap_function => 0.0625,
        :redirect_connection => 0.0625,
    ),
    "shrink_stable" => Dict(
        :identity => 0.90,
        :add_function => 0.02,
        :remove_function => 0.03,
        :swap_function => 0.025,
        :redirect_connection => 0.025,
    ),
    "shrink_stable_harsh" => Dict(
        :identity => 108 / 120,
        :add_function => 2 / 120,
        :remove_function => 4 / 120,
        :swap_function => 3 / 120,
        :redirect_connection => 3 / 120,
    ),
)

GAUSSIAN_NOISE_STD = Dict(
    "high" => 0.1,
    "moderate" => 0.05,
    "low" => 0.01,
)

function make_mutators(substrate::FunctionGraphSubstrate) 
    function_set = FUNCTION_SETS[substrate.function_set]
    function_probabilities = Dict(
        Symbol(func) => 1 / length(function_set) for func in function_set
    )
    mutation_probabilities = MUTATION_PROBABILITIES[substrate.mutation]
    println("MUTATION PROBS: ", mutation_probabilities)
    noise_std = GAUSSIAN_NOISE_STD[substrate.noise_std]
    mutator = FunctionGraphMutator(
        function_probabilities = function_probabilities,
        mutation_probabilities = mutation_probabilities,
        noise_std = noise_std,
        validate_genotypes = false,
    )

    mutators = [mutator]
    return mutators
end

const ID_TO_SUBSTRATE_MAP = Dict(
    "finite_state_machines" => FiniteStateMachineSubstrate,
    "gnarl_networks" => GnarlNetworkSubstrate, 
    "function_graphs" => FunctionGraphSubstrate,
)

function load_substrate(file::File)
    base_path = "configuration/substrate"
    substrate_id = read(file["$base_path/id"])
    substrate_type = get(ID_TO_SUBSTRATE_MAP, substrate_id, nothing)

    if substrate_type === nothing
        error("Unknown substrate type: $substrate_id")
    end
    substrate = load_type(substrate_type, file, base_path)
    return substrate
end

function get_substrate(id::String; kwargs...)
    type = get(ID_TO_SUBSTRATE_MAP, id, nothing)
    if type === nothing
        error("Unknown substrate type: $id")
    end
    substrate = type(; id = id, kwargs...)
    return substrate
end
