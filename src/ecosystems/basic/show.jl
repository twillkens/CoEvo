
function Base.show(io::IO, eco::BasicEcosystem)
    print(io, "Eco(id: ", eco.id, ", species: ", keys(eco.species), ")")
end


function show(io::IO, c::BasicEcosystemCreator)
    print(io, "BasicEcosystemCreator(id: ", c.id, 
          ", trial: ", c.trial,
          ", rng: ", typeof(c.rng), 
          ", species: ", keys(c.species_creators), 
          ", interactions: ", c.job_creator.interactions,")")
end
