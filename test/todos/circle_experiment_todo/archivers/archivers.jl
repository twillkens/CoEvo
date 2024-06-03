import ....Interfaces: create_archivers
using ...Archivers.Fitness: FitnessArchiver
using ...Archivers.GenotypeSize: GenotypeSizeArchiver
using ...Archivers.Ecosystems: EcosystemArchiver
using ...Archivers.Globals: GlobalStateArchiver
using ...Archivers.Modes: ModesArchiver

function create_archivers(::CircleExperimentConfiguration)
    archivers = [
        GlobalStateArchiver(), 
        FitnessArchiver(),
        GenotypeSizeArchiver(), 
        ModesArchiver(),
        EcosystemArchiver()
    ]
    return archivers
end
