module Results

export Basic

using DataStructures: SortedDict

include("abstract/abstract.jl")

include("interfaces/interfaces.jl")

include("basic/basic.jl")
using .Basic: Basic

end