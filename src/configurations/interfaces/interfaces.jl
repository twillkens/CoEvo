module Interfaces

using ..Configurations.Abstract: Configuration
using ...Ecosystems.Abstract: EcosystemCreator

function make_ecosystem_creator(configuration::Configuration)::EcosystemCreator
    throw(ErrorException("`make_ecosystem_creator` not implemented for $(typeof(configuration))"))
end

end