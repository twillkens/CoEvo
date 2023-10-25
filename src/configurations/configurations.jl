module Configurations

export PredictionGames

import ..Ecosystems: evolve!

using JLD2: @save
using StableRNGs: StableRNG
using ..Performers.Cache: CachePerformer
using ..Counters: Counter
using ..MatchMakers.AllvsAll: AllvsAllMatchMaker
using ..Replacers.Truncation: TruncationReplacer
using ..Recombiners.Clone: CloneRecombiner
using ..Ecosystems: EcosystemCreator

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("helpers/helpers.jl")

include("prediction_games/prediction_games.jl")
using .PredictionGames: PredictionGames, PredictionGameTrialConfiguration

end