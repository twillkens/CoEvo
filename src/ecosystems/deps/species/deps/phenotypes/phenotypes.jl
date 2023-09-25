module Phenotypes

export DefaultPhenotypeConfiguration
export PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

include("types/default.jl")

include("types/player_pianos/player_pianos.jl")

using .PlayerPianos: PlayerPianoPhenotype, PlayerPianoPhenotypeConfiguration

end