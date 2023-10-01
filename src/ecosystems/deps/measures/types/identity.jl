module Identity

export IndividualIdentityMeasureSet

using ....Ecosystems.Species.Individuals: Individual
using ..Abstract: MeasureSet

struct IndividualIdentityMeasureSet <: MeasureSet
    individuals::Dict{Int, <:Individual}
end

end