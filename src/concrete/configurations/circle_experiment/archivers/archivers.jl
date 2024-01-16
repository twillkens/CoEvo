import ....Interfaces: create_archivers
using ...Archivers.Fitness: FitnessArchiver
using ...Archivers.GenotypeSize: GenotypeSizeArchiver
using ...Archivers.Ecosystems: EcosystemArchiver
using ...Archivers.Globals: GlobalStateArchiver

function create_archivers(::CircleExperimentConfiguration)
    archivers = [GlobalStateArchiver(), FitnessArchiver(), GenotypeSizeArchiver(), EcosystemArchiver()]
    return archivers
end
