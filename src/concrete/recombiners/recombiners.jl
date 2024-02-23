module Recombiners

export Clone, Identity, HorizontalGeneTransfer, NPointCrossover

include("clone/clone.jl")
using .Clone: Clone

include("identity/identity.jl")
using .Identity: Identity

include("horizontal_gene_transfer/horizontal_gene_transfer.jl")
using .HorizontalGeneTransfer: HorizontalGeneTransfer

include("n_point_crossover/n_point_crossover.jl")
using .NPointCrossover: NPointCrossover

end
