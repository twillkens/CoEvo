import ....Interfaces: create_archivers
using ...Archivers.Fitness: FitnessArchiver
using ...Archivers.GenotypeSize: GenotypeSizeArchiver

function create_archivers(::CircleExperimentConfiguration)
    archivers = [FitnessArchiver(), GenotypeSizeArchiver()]
    return archivers
end
