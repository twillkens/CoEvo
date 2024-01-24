module Globals

export GlobalStateArchiver

import ....Interfaces: archive!
using Distributed
using HDF5: h5open
using ....Abstract
using ....Interfaces

struct GlobalStateArchiver <: Archiver
end

function archive!(::GlobalStateArchiver, state::State)
    rng_state = string(state.rng.state)
    current_individual_id = state.reproducer.individual_id_counter.current_value
    current_gene_id = state.reproducer.gene_id_counter.current_value
    reproduction_time = state.timers.reproduction_time
    simulation_time = state.timers.simulation_time
    evaluation_time = state.timers.evaluation_time
    generation = state.generation
    trial = state.id
    ecosystem_id = state.ecosystem.id

    println("------Trial: $trial, Generation: $generation, Ecosystem: $ecosystem_id------")
    println("worker_id = $(myid())")
    println("rng_state = $rng_state")
    println("individual_id: $current_individual_id, gene_id: $current_gene_id")
    println("reproduction_time: $reproduction_time, " * 
            "simulation_time: $simulation_time, " * 
            "evaluation_time: $evaluation_time"
    )
end

end