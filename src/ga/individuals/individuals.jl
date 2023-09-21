module Individuals

using ...CoEvo: Genotype, Individual

struct Indiv{G <: Genotype} <: Individual
    id::Int
    geno::G
    pid::Int
end

Indiv(id::Int, geno::Genotype) = Indiv(id, geno, 0)

end