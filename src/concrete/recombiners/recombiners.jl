module Recombiners

export Clone, Identity, HorizontalGeneTransfer

include("clone/clone.jl")
using .Clone: Clone

include("identity/identity.jl")
using .Identity: Identity

include("horizontal_gene_transfer/horizontal_gene_transfer.jl")
using .HorizontalGeneTransfer: HorizontalGeneTransfer

end
