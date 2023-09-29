module Interfaces


function save_individuals!(
    archiver::Archiver, 
    gen::Int, 
    jld2_file::File, 
    species_id_indiv_evals::OrderedDict{String, OrderedDict{<:Individual, <:Evaluation}}, 
    generational_type::String
)
    throw(ErrorException("save_individuals! not implemented for $(typeof(archiver))"))
end


end