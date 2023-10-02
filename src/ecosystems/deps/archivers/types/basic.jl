module Basic

export BasicArchiver

using DataStructures: OrderedDict
using JLD2: JLDFile, Group, jldopen

using ..Utilities: get_or_make_group!

using ..Archivers.Abstract: Archiver
using ...Reporters.Abstract: Report


Base.@kwdef struct BasicArchiver <: Archiver 
    jld2_path::String = "archive.jld2"
end


function archive!(archiver::BasicArchiver, gen::Int, report::Report)
end

# # Save an individual to a JLD2.Group
# function save_individual!(
#     archiver::DefaultArchiver, indiv_group::Group, indiv::BasicIndividual
# )
#     indiv_group["parent_ids"] = indiv.parent_ids
#     geno_group = Group(indiv_group, "geno")
#     save_genotype!(archiver, geno_group, indiv.geno)
# end
# 
# function save_individuals!(
#     archiver::DefaultArchiver, 
#     gen::Int, 
#     jld2_file::JLDFile, 
#     species_id_indiv_evals::OrderedDict{String, OrderedDict{<:Individual, <:Evaluation}}, 
#     generational_type::String
# )
#     base_path = "indivs/$gen"
#     for (species_id, indiv_evals) in species_id_indiv_evals
#         species_path = "$base_path/$species_id/$generational_type"
#         for indiv in keys(indiv_evals)
#             indiv_path = "$species_path/$(indiv.id)"
#             indiv_group = get_or_make_group!(jld2_file, indiv_path)
#             save_individual!(archiver, indiv_group, indiv)
#         end
#     end
#     close(jld2_file)
# end

end