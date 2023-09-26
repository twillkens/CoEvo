using StableRNGs: StableRNG
using DataStructures: OrderedDict
using Test

include("../src/CoEvo.jl")
using .CoEvo
using .CoEvo.Ecosystems.Species.Substrates.GeneticPrograms: BasicGeneticProgramGenotypeConfiguration
using .CoEvo.Ecosystems.Species.Substrates.GeneticPrograms: BasicGeneticProgramGenotype
using .CoEvo.Ecosystems.Species.Substrates.GeneticPrograms.Genes: ExpressionNodeGene
using .CoEvo.Ecosystems.Species.Substrates.GeneticPrograms.Utilities: protected_division

BasicGeneticProgramGenotypeConfiguration()(StableRNG(42), Counter())
"""
    dummygeno() -> BasicGeneticProgramGenotype

Create a sample `BasicGeneticProgramGenotype` object for testing purposes.
"""
function dummygeno()
    root = ExpressionNodeGene(1, nothing, +, [2, 3])
    node2 = ExpressionNodeGene(2, 1, 2.0)
    node3 = ExpressionNodeGene(3, 1, 3.0)

    return BasicGeneticProgramGenotype(
        root_id = 1,
        functions = Dict(1 => root),
        terminals = Dict(2 => node2, 3 => node3)
    )
end

"""
    big_geno() -> BasicGeneticProgramGenotype

Create a more complex `BasicGeneticProgramGenotype` object for further testing.
"""
function big_geno()
    funcs = Dict(
        1 => ExpressionNodeGene(1, nothing, +, [2, 3]),
        2 => ExpressionNodeGene(2, 1, -, [5, 6]),
        3 => ExpressionNodeGene(3, 1, *, [7, 8]),
        4 => ExpressionNodeGene(4, nothing, protected_division, [9, 10])
    )
    terms = Dict(
        5 => ExpressionNodeGene(5, 2, 5.0),
        6 => ExpressionNodeGene(6, 2, 6.0),
        7 => ExpressionNodeGene(7, 3, 7.0),
        8 => ExpressionNodeGene(8, 3, 8.0),
        9 => ExpressionNodeGene(9, 4, 9.0),
        10 => ExpressionNodeGene(10, 4, 10.0)
    )

    return BasicGeneticProgramGenotype(root_id=1, functions=funcs, terminals=terms)
end
println(dummygeno())