export make_ecosystem_creator

function run!(configuration::Configuration)
    throw(ErrorException(
        "`run!` not implemented for $(typeof(configuration))"
    ))
end