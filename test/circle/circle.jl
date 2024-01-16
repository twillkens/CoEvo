using CoEvo.Concrete.Configurations.CircleExperiment
using CoEvo.Concrete.States.Basic
using CoEvo.Abstract
using CoEvo.Interfaces
using CoEvo.Utilities
using CoEvo.Concrete.Archivers.Ecosystems: EcosystemArchiver
using HDF5

ENV["COEVO_TRIAL_DIR"] = "trials"

rm("trials/1", force = true, recursive = true)
file = open("trials/1.out", "w")
redirect_stdout(file)
configuration = CircleExperimentConfiguration(n_generations = 10, checkpoint_interval = 5, species = "test")
state = evolve(configuration)
println("RNGRNG = $(state.rng.state)")
close(file)

rm("trials/1", force = true, recursive = true)

file = open("trials/2.out", "w")
redirect_stdout(file)
state = evolve(configuration)
println("RNGRNG_AFTER = $(state.rng.state)")
close(file)

rm("trials/1", force = true, recursive = true)

file = open("trials/3.out", "w")
redirect_stdout(file)
state = evolve(configuration, 5)
println("\n CRASH")
state = evolve(configuration)
println("RNGRNG_AFTER_CRASH = $(state.rng.state)")
close(file)



##dict = convert_to_dict(state.ecosystem)
##ecosystem = create_from_dict(state.reproducer.ecosystem_creator, dict, state)
##println(ecosystem)
#
##archiver = EcosystemArchiver()
#
##archive!(archiver, state)
#archive_directory = configuration.archive_directory
#
#f = h5open("$archive_directory/generations/1.h5", "r")
#
#state_dict = load_dict_from_hdf5(f, "/")
#
#state = create_from_dict(BasicEvolutionaryStateCreator(), state_dict, configuration)
#
#println("rng_state = $(state.rng.state)")
#
#evolve!(state, 200)


#println(state)