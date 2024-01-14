export create_reproducer, create_simulator, create_evaluator, create_archivers

using ..Abstract

create_reproducer(config::Configuration) = error("create_reproducer not implemented for configuration $config")

create_simulator(config::Configuration) = error("create_simulator not implemented for configuration $config")

create_evaluator(config::Configuration) = error("create_evaluator not implemented for configuration $config")

create_archivers(config::Configuration) = error("create_archivers not implemented for configuration $config")

