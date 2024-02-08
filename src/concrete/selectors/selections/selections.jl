module Selections

export BasicSelection

using ....Abstract

struct BasicSelection{R <: Record} <: Selection
    records::Vector{R}
end

end