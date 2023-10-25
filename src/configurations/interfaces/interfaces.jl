export make_ecosystem_creator

function make_ecosystem_creator(configuration::Configuration)::EcosystemCreator
    throw(ErrorException(
        "`make_ecosystem_creator` not implemented for $(typeof(configuration))"
    ))
end
