export DefaultPhenoCfg, Pheno

struct DefaultPhenoCfg <: PhenoConfig end

function(phenocfg::PhenoConfig)(indiv::BasicIndiv)
    phenocfg(indiv.ikey, indiv.geno)
end

struct Pheno{T} <: Phenotype
    ikey::IndivKey
    pheno::T
end

function(cfg::DefaultPhenoCfg)(ikey::IndivKey, geno::Genotype)
    Pheno(ikey, geno)
end