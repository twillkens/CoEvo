export Substrate, get_n_population, get_n_children, make_individual_creator, make_recombiner
export GnarlNetworkSubstrate, FunctionGraphSubstrate
export make_genotype_creator, make_phenotype_creator, make_mutators
export load_substrate, get_substrate

using ...Names

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
end

function FunctionGraphSubstrate(;
    id::String = "function_graphs",
    n_population::Int = 10, 
    n_children::Int = 10, 
    n_nodes_per_output::Int = 1, 
    kwargs...
)
    substrate = FunctionGraphSubstrate(
        id,
        n_population,
        n_children,
        n_nodes_per_output
    )
    return substrate
end

function archive!(substrate::FunctionGraphSubstrate, file::File)
    base_path = "configuration/substrate"
    file["$base_path/id"] = substrate.id
    file["$base_path/n_population"] = substrate.n_population
    file["$base_path/n_children"] = substrate.n_children
    file["$base_path/n_nodes_per_output"] = substrate.n_nodes_per_output
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

make_mutators(::FunctionGraphSubstrate) = [FunctionGraphMutator()]

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
