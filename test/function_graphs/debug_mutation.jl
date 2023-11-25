using CoEvo.Names
using Random

function apply_mutation_storm(
    mutator::FunctionGraphMutator, 
    genotype::FunctionGraphGenotype, 
    n_mutations::Int, 
    test_output::Bool = false
)
    random_number_generator = Random.MersenneTwister(rand(UInt64))
    gene_id_counter = BasicCounter(7)
    phenotype_creator = LinearizedFunctionGraphPhenotypeCreator()
    output_length_equals_expected = Bool[]

    
    for _ in ProgressBar(1:n_mutations)
        genotype = mutate(mutator, random_number_generator, gene_id_counter, genotype)
        #validate_genotype(genotype)
        if test_output
            phenotype = create_phenotype(phenotype_creator, genotype)
            reset!(phenotype)
            input_values = [1.0, -1.0]
            outputs = [round(act!(phenotype, input_values)[1], digits=3) for _ in 1:10]
            if any(isnan, outputs)
                println("NaNs found")
                println(genotype)
                println(phenotype)
                println(input_values)
                println(outputs)
                throw(ErrorException("NaNs found"))
            end
            #println(outputs)
            push!(output_length_equals_expected, length(outputs) == 10)
        end
    end
    all(output_length_equals_expected)
end