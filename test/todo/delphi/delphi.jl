using Test
using Random
using StableRNGs
include("../../src/Coevolutionary.jl")
using .Coevolutionary

@testset "delphi" begin
    
@testset "Genotype" begin
    # genome initialization with default value 0
    cfg = DefaultVectorGenoConfig(width=10, default_val=0.0)
    geno_zeros = cfg("AllZeros")
    @test typeof(geno_zeros) == VectorGeno{Float64}
    @test geno_zeros.key == "AllZeros"
    @test geno_zeros.genes == fill(0.0, 10)

    # genome initialization with random values
    cfg = DelphiGenoConfig(width=5, rng = StableRNG(123), min=0.0, max=0.05)
    geno_rand = cfg("Random")
    @test typeof(geno_rand) == VectorGeno{Float64}
    @test sum(geno_rand.genes) < 0.25
    @test sum(geno_rand.genes) > 0
end


@testset "Population" begin
    geno_cfg = DefaultVectorGenoConfig(width=10, default_val=0.0)
    pop_cfg = GenoPopConfig(key = "A", n_genos = 10, geno_cfg = geno_cfg)
    popA = (pop_cfg)()
    genos = Dict{String, Genotype}(popA)
    @test length(genos) == 10
    @test all(["A-$(i)" in keys(genos) for i in 1:10])
    @test sum([sum(g.genes) for g in values(genos)]) == 0

    geno_cfg = DefaultVectorGenoConfig(width=10, default_val=true)
    pop_cfg = GenoPopConfig(key = "B", n_genos = 10, geno_cfg = geno_cfg)
    popB = (pop_cfg)()
    genos = Dict{String, Genotype}(popB)
    @test length(genos) == 10
    @test all(["B-$(i)" in keys(genos) for i in 1:10])
    @test sum([sum(g.genes) for g in values(genos)]) == 100

    pops = Set([popA, popB])
    popdict = Dict{String, Population}(pops)
    @test length(popdict) == 2
    @test popdict["A"] == popA
    @test popdict["B"] == popB
end

@testset "Order/Recipes1" begin
    rng = StableRNG(123)
    cfg = DelphiGenoConfig(width=5, rng = StableRNG(123), min=0.0, max=0.05)
    popA = GenoPopConfig(
        key = "A",
        n_genos = 10,
        geno_cfg = cfg)()
    popB = GenoPopConfig(
        key = "B",
        n_genos = 10,
        geno_cfg = cfg)()
    pops = Set([popA, popB])
    pheno_cfg = DelphiPhenoConfig()
    order = AllvsAllOrder(
        domain = COADomain(),
        outcome = TestPairOutcome,
        subjects_key = "A",
        subjects_cfg = pheno_cfg,
        tests_key = "B",
        tests_cfg = pheno_cfg,)
    recipes = (order)(popA, popB)
    @test length(recipes) == 100
    recipe_set = Set{Set{Recipe}}(order, pops, 5)
    @test all([length(recipes) == 20 for recipes in recipe_set])
end

# @testset "Phenotypes/Outcomes" begin
#     genoA = VectorGeno("A", [0.1, 0.2, 0.3], Set{String}())
#     genoB = VectorGeno("B", [0.0, 0.1, 0.2], Set{String}())
#     pheno_cfg = DelphiPhenoConfig()
#     phenoA = pheno_cfg(genoA)
#     phenoB = pheno_cfg(genoB)
#     @test typeof(phenoA) == DelphiPheno
#     @test sum(phenoA.traits) ≈ 0.6
#     @test sum(phenoB.traits) ≈ 0.3
#     o = DelphiOutcome(1, COADomain(), phenoA, phenoB)
#     @test o.subject_score == 1.0
#     @test o.test_score == -1.0

#     genoA = VectorGeno("A", [0.1, 0.2, 0.3], Set{String}())
#     genoB = VectorGeno("B", [0.0, 0.1, 0.4], Set{String}())
#     pheno_cfg = DelphiPhenoConfig()
#     phenoA = pheno_cfg(genoA)
#     phenoB = pheno_cfg(genoB)
#     o = DelphiOutcome(1, COODomain(), phenoA, phenoB)
#     @test o.subject_score == -1.0
#     @test o.test_score == 1.0

#     genoA = VectorGeno("A", [0.1, 0.2, 0.6], Set{String}())
#     genoB = VectorGeno("B", [0.2, 0.3, 0.5], Set{String}())
#     pheno_cfg = DelphiPhenoConfig()
#     phenoA = pheno_cfg(genoA)
#     phenoB = pheno_cfg(genoB)
#     o = DelphiOutcome(1, COODomain(), phenoA, phenoB)
#     @test o.subject_score == 1.0
#     @test o.test_score == -1.0
# end

# @testset "Outcomes: DelphiPheno" begin
#     rng = StableRNG(123)
#     geno_cfg = DefaultVectorGenoConfig(width=10, default_val=1.0)
#     popA = GenoPopConfig(key="A", n_genos=10, geno_cfg=geno_cfg)()
#     geno_cfg = DefaultVectorGenoConfig(width=10, default_val=0.0)
#     popB = GenoPopConfig(key="B", n_genos=10, geno_cfg=geno_cfg)()
#     pops = Set([popA, popB])
#     domain = COADomain()
#     pheno_cfg = DelphiPhenoConfig()
#     orderA = AllvsAllOrder(
#         domain = domain,
#         outcome = TestPairOutcome,
#         subjects_key = "A",
#         subjects_cfg = pheno_cfg,
#         tests_key = "B",
#         tests_cfg = pheno_cfg,)
#     orders = Set([orderA])
#     cfg = SerialJobConfig()
#     job = cfg(orders, pops)
#     outcomes = Set{Outcome}(job)
#     @test length(outcomes) == 100
#     flag = true
#     for outcome in outcomes
#         if outcome.scores[outcome.subject_key] != 1.0 
#             flag = false
#         end
#         if outcome.scores[outcome.test_key] != -1.0
#             flag = false
#         end
#     end
#     @test flag
# end

end