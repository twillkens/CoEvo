export FilterTag, FilterIndiv, FilterResults

struct FilterTag
    gen::Int
    spid::String
    iid::String
    prevtag::Int
    currtag::Int
end

mutable struct FilterIndiv{
    G1 <: Union{FSMGeno, Nothing}, G2 <: Union{FSMGeno, Nothing}, G3 <: FSMGeno
}
    ftag::FilterTag
    geno::G1
    mingeno::G2
    modegeno::G3
    minfitness::Float64
    modefitness::Float64
    min_eplen::Float64
    mode_eplen::Float64
end

