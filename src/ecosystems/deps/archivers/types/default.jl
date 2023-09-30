module Default

export DefaultArchiver

using DataStructures: OrderedDict
using JLD2: File, Group, jldopen

using ..Utilities: get_or_make_group!

using ...Ecosystems.Species.Evaluators.Abstract: Evaluation
using ...Ecosystems.Species.Individuals.Basic: BasicIndividual
using ...Ecosystems.Performers.Results.Abstract: Result
using ..Abstract: Archiver, Individual, Evaluation


"""
    DefaultArchiver

A structure representing the default archiver for saving individual and population data 
in genetic algorithms to a JLD2 file.

# Fields:
- `save_pop::Bool`: Whether or not to save the entire population. Default is `false`.
- `save_children::Bool`: Whether or not to save the offspring. Default is `false`.
- `jld2_path::String`: The path to the JLD2 file where data will be saved. Default is "archive.jld2".
"""
Base.@kwdef struct DefaultArchiver <: Archiver 
    save_pop::Bool = false
    save_children::Bool = false
    jld2_path::String = "archive.jld2"
end

# Save an individual to a JLD2.Group
function save_individual!(
    archiver::DefaultArchiver, indiv_group::Group, indiv::BasicIndividual
)
    indiv_group["parent_ids"] = indiv.parent_ids
    geno_group = Group(indiv_group, "geno")
    save_genotype!(archiver, geno_group, indiv.geno)
end

function save_individuals!(
    archiver::DefaultArchiver, 
    gen::Int, 
    jld2_file::File, 
    species_id_indiv_evals::OrderedDict{String, OrderedDict{<:Individual, <:Evaluation}}, 
    generational_type::String
)
    base_path = "indivs/$gen"
    for (species_id, indiv_evals) in species_id_indiv_evals
        species_path = "$base_path/$species_id/$generational_type"
        for indiv in keys(indiv_evals)
            indiv_path = "$species_path/$(indiv.id)"
            indiv_group = get_or_make_group!(jld2_file, indiv_path)
            save_individual!(archiver, indiv_group, indiv)
        end
    end
    close(jld2_file)
end

end