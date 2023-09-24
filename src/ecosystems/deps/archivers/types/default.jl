export DefaultArchiver

using DataStructures: OrderedDict
using JLD2: File, Group, jldopen
using .Utilities: get_or_make_group!
using ...CoEvo.Abstract: Archiver, Report, Individual, Evaluation
using ...CoEvo.Ecosystems.Species.Evaluations: ScalarFitnessEvaluation
using ...CoEvo.Ecosystems.Species.Individuals: AsexualIndividual, SexualIndividual
using ...CoEvo.Ecosystems.Species.Genotypes: VectorGenotype

Base.@kwdef struct DefaultArchiver <: Archiver 
    save_pop::Bool = false
    save_children::Bool = false
    jld2_path::String = "archive.jld2"
end

# function(archiver::DefaultArchiver)(
#     gen::Int,
#     report::Report
# )
#     jld2_file = jldopen(archiver.jld2_path, "a+")
#     # if archiver.save_pop
#     #     save_individuals!(archiver, gen, jld2_file, all_pop_evals, "pop")
#     # end 
#     # if archiver.save_children
#     #     save_individuals!(archiver, gen, jld2_file, all_children_evals, "children")
#     # end
#     [process_report(archiver, report) for report in reports]
#     close(jld2_file)
# end


# Save an individual to a JLD2.Group
function save_individual!(
    archiver::DefaultArchiver, indiv_group::Group, indiv::AsexualIndividual
)
    indiv_group["parent_id"] = indiv.parent_id
    geno_group = Group(indiv_group, "genotype")
    save_genotype!(archiver, geno_group, indiv.geno)
end

# Save an individual to a JLD2.Group
function save_individual!(
    archiver::DefaultArchiver, indiv_group::Group, indiv::SexualIndividual
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
