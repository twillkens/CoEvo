module IndividualIdentityMeasureSet

using ....Ecosystems.Species.Individuals.Abstract: Individual
using ..Abstract: MeasureSet

struct IndividualsMeasureSet <: MeasureSet
    individuals::Dict{Int, <:Individual}
end

end