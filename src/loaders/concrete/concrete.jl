export FiniteStateMachineGenotypeLoader, GnarlNetworkGenotypeLoader, load_ecosystem
export BasicVectorGenotypeLoader, EcosystemLoader, FunctionGraphGenotypeLoader
# export GeneticProgramGenotypeLoader

include("fsms/fsms.jl")
using .FiniteStateMachines: FiniteStateMachineGenotypeLoader

#include("genetic_programs/genetic_programs.jl")
#using .GeneticPrograms: GeneticProgramGenotypeLoader
#
include("gnarl_networks/gnarl_networks.jl")
using .GnarlNetworks: GnarlNetworkGenotypeLoader
#
include("vectors/vectors.jl")
using .Vectors: BasicVectorGenotypeLoader    

include("function_graphs/function_graphs.jl")
using .FunctionGraphs: FunctionGraphGenotypeLoader


struct EcosystemLoader <: Loader
    jld2_filepath::String
end

function load_individual(loader::Loader, individual_id::Int, individual_group::Group)
    genotype = load_genotype(loader, individual_group["genotype"])
    parent_ids = individual_group["parent_ids"]
    individual = BasicIndividual(individual_id, genotype, parent_ids)
    return individual
end


function load_population(
    species_loader::Loader, 
    jld2_file::JLDFile, 
    gen::Int, 
    species_id::String,
    pop_ids::Set{Int},
    population_dict::Dict{Int, Individual} = Dict{Int, Individual}()
)
    children_group = jld2_file["individuals/$gen/$species_id/children"]
    for individual_id_str in keys(children_group) 
        individual_id = parse(Int, individual_id_str)
        if individual_id in pop_ids
            individual_group = children_group[individual_id_str]
            population_dict[individual_id] = load_individual(
                species_loader, individual_id, individual_group
            )
            delete!(pop_ids, individual_id)
        end
    end
    if length(pop_ids) == 0
        return population_dict
    elseif gen == 1
        error("Could not find all individuals in population")
    else
        prev_gen = gen - 1
        # Recursive call to get the previous generation's individuals
        return load_population(
            species_loader, jld2_file, prev_gen, species_id, pop_ids, population_dict
        )
    end
end


function load_species(
    species_loader::Loader, 
    jld2_file::JLDFile, 
    gen::Int, 
    species_id::String, 
    species_path::String,
)
    children_group = jld2_file["$species_path/children"]
    children = Dict{Int, Individual}()
    
    for individual_id_str in keys(children_group) 
        individual_id = parse(Int, individual_id_str)
        individual_group = children_group[individual_id_str]
        children[individual_id] = load_individual(
            species_loader, individual_id, individual_group
        )
    end
    
    if gen > 1
        pop_ids = Set(jld2_file["$species_path/population_ids"])
        prev_gen = gen - 1
        population = load_population(species_loader, jld2_file, prev_gen, species_id, pop_ids)
    else
        population = children
        children = Dict{Int, Individual}()
    end
    
    return BasicSpecies(species_id, population, children)
end

function load_ecosystem(loader::EcosystemLoader, species_loaders::Dict{String, <:Loader}, gen::Int)
    #println("Loading generation $gen")
    
    jld2_file = jldopen(loader.jld2_filepath, "r")
    base_path = "individuals/$gen"
    
    species_dict = Dict{String, BasicSpecies}()
    
    # Check if the base_path exists in the file
    for species_id in keys(jld2_file[base_path])
        species_path = "$base_path/$species_id"
        species_loader = species_loaders[species_id]
        species_dict[species_id] = load_species(
            species_loader, jld2_file, gen::Int, species_id, species_path
        )
    end
    
    close(jld2_file)
    
    return BasicEcosystem("gen_$gen", species_dict)
end
