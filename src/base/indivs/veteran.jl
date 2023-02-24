export Veteran, VetSpecies
export dummyvets, clone
export iid, spid

struct Veteran{I <: Individual, R <: Real} <: Individual
    ikey::IndivKey
    indiv::I
    rdict::Dict{TestKey, R}
end

function clone(iid::UInt32, parent::Veteran)
    clone(iid, parent.indiv)
end