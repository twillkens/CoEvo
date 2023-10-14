module Concrete

export BasicExpressionNodeGene, BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator
export ModiExpressionNodeGene, ModiGeneticProgramGenotype, ModiGeneticProgramGenotypeCreator

include("basic.jl")
using .Basic: BasicExpressionNodeGene, BasicGeneticProgramGenotype, BasicGeneticProgramGenotypeCreator

include("modi.jl")
using .Modi: ModiExpressionNodeGene, ModiGeneticProgramGenotype, ModiGeneticProgramGenotypeCreator

end