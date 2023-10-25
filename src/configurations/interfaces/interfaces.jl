export make_ecosystem_id, make_species_creators, make_interactions, make_archive_path

function make_ecosystem_id(configuration::Configuration)::String
    throw(ErrorException(
        "`make_ecosystem_id` not implemented for $(typeof(configuration))"
    ))
end

function make_species_creators(configuration::Configuration)
    throw(ErrorException(
        "`make_species_creators` not implemented for $(typeof(configuration))"
    ))
end

function make_interactions(configuration::Configuration)
    throw(ErrorException(
        "`make_interactions` not implemented for $(typeof(configuration))"
    ))
end

function make_reporters(configuration::Configuration)
    throw(ErrorException(
        "`make_reporters` not implemented for $(typeof(configuration))"
    ))
end

function make_archive_path(configuration::Configuration)
    throw(ErrorException(
        "`make_archive_path` not implemented for $(typeof(configuration))"
    ))
end