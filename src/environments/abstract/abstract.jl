export Environment, EnvironmentCreator

abstract type Environment{D <: Domain} end

abstract type EnvironmentCreator{D <: Domain} end
