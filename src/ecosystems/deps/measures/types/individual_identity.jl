module IndividualIdentity

export IndividualsMeasureSet

using ....Ecosystems.Species.Individuals.Abstract: Individual
using ..Abstract: MeasureSet

struct IndividualIdentityMeasureSet <: MeasureSet
    individuals::Dict{Int, <:Individual}
end

end