module Default

export DefaultEnvironmentCreator

using ....Environments.Abstract: EnvironmentCreator
using ....Domains.Abstract: Domain

struct DefaultEnvironmentCreator{D <: Domain} <: EnvironmentCreator{D} end

end