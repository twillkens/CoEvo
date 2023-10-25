module Configurations

export PredictionGame

import ..Ecosystems: evolve!

using JLD2: @save
using StableRNGs: StableRNG
using ..Performers.Cache: CachePerformer
using ..Counters.Basic: BasicCounter
using ..MatchMakers.AllvsAll: AllvsAllMatchMaker
using ..Replacers.Truncation: TruncationReplacer
using ..Recombiners.Clone: CloneRecombiner
using ..Ecosystems: EcosystemCreator
using ..Ecosystems.Basic: BasicEcosystemCreator
using ..Selectors.FitnessProportionate: FitnessProportionateSelector
using ..Selectors.Tournament: TournamentSelector
using ..Evaluators.ScalarFitness: ScalarFitnessEvaluator
using ..Evaluators.NSGAII: NSGAIIEvaluator
using ..Jobs.Basic: BasicJobCreator
using ..Archivers.Basic: BasicArchiver
using ..States.Basic: BasicCoevolutionaryStateCreator

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("helpers/helpers.jl")

include("numbers_game/numbers_game.jl")
using .NumbersGame: NumbersGame

include("prediction_game/prediction_game.jl")
using .PredictionGame: PredictionGame

end