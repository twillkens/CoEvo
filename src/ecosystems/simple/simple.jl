module Simple

export BasicEcosystem, SimpleEcosystemCreator, create_ecosystem, evolve!, get_individuals
export get_species

import ...Individuals: get_individuals
import ...Species: get_species
import ...Evaluators: evaluate
import ..Ecosystems: create_ecosystem, evolve!

using DataStructures: SortedDict
using Random: AbstractRNG
using StableRNGs: StableRNG
using JLD2: @save
using ...Counters: Counter
using ...Counters.Basic: BasicCounter
using ...Species: AbstractSpecies
using ...Evaluators: Evaluation, Evaluator
using ...SpeciesCreators: SpeciesCreator, create_species
using ...SpeciesCreators.Basic: BasicSpeciesCreator
using ...Jobs: JobCreator, create_jobs
using ...Performers: Performer
using ...Interactions: Interaction
using ...Results: Result, get_individual_outcomes, get_observations
using ...Observers: Observation
#using ...Observers.Null: NullObservation
using ...Reporters: Reporter, Report, create_reports
using ...Archivers: Archiver, archive!
using ...Performers: perform
using ...States.Basic: BasicCoevolutionaryStateCreator, BasicCoevolutionaryState
using ...States: State, StateCreator
using ..Ecosystems: Ecosystem, EcosystemCreator

include("ecosystem.jl")

include("show.jl")

include("evaluate.jl")

include("create_state.jl")

include("create_ecosystem.jl")

include("evolve.jl")

end
