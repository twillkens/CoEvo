export create_reproducers, create_simulator, create_evaluator, create_archivers, load_state
export create_archive_directory, evolve, create_state_from_dict, get_ecosystem_creator
export create_reproducer, create_evaluators

using HDF5
using ..Utilities
using ..Abstract

get_ecosystem_creator(config::Configuration) = error("get_ecosystem_creator not implemented for configuration $config")

create_reproducer(config::Configuration) = error("create_reproducer not implemented for configuration $config")

create_reproducers(config::Configuration) = error("create_reproducers not implemented for configuration $config")

create_simulator(config::Configuration) = error("create_simulator not implemented for configuration $config")

create_evaluator(config::Configuration) = error("create_evaluator not implemented for configuration $config")

create_evaluators(config::Configuration) = error("create_evaluators not implemented for configuration $config")

create_archivers(config::Configuration) = error("create_archivers not implemented for configuration $config")

load_state(config::Configuration, generation::Int) = error("load_state not implemented for configuration $config")

create_archive_directory(config::Configuration) = error("create_archive_directory not implemented for configuration $config")

evolve(config::Configuration) = error("evolve not implemented for configuration $config")

create_state_from_dict(state_dict::Dict, config::Configuration) = error("create_state_from_dict not implemented for configuration $config")

