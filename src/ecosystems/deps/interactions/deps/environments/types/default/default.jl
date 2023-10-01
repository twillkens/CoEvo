module Default

export DefaultEnvironmentCreator

using ....Environments.Abstract: EnvironmentCreator

struct DefaultEnvironmentCreator <: EnvironmentCreator end

end