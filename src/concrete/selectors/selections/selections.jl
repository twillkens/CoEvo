module Selections

export BasicSelection, BasicRecord

using ....Abstract

struct BasicSelection{R <: Record} <: Selection
    records::Vector{R}
end

struct BasicRecord{I <: Individual} <: Record
    individual::I
    fitness::Float64
end

function BasicSelection(individuals::Vector{<:Individual})
    records = [BasicRecord(individual, 0.0) for individual in individuals]
    return BasicSelection(records)
end


end