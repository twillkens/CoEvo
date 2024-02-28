using StatsBase

function print_info(species::SpreadDodoSpecies)
    info = []
    for individual in species.parents
        #max_dimension = argmax(individual.genotype.genes)
        #v = round(individual.genotype.genes[max_dimension], digits=2)
        ##i = (max_dimension, v, temp)
        #i = (max_dimension, v, individual.age)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("PARENT_INFO = ", info)
    info = []
    for individual in species.children
        #max_dimension = argmax(individual.genotype.genes)
        #v = round(individual.genotype.genes[max_dimension], digits=2)
        #i = (max_dimension, v)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("CHILDREN_INFO = ", info)
    info = []
    for individual in species.explorers
        #max_dimension = argmax(individual.genotype.genes)
        #v = round(individual.genotype.genes[max_dimension], digits=2)
        #i = (max_dimension, v)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("EXPLORER_INFO = ", info)
    println("LENGTH_RETIREES = ", length(species.retirees))
    info = []
    for individual in species.retirees
        #max_dimension = argmax(individual.genotype.genes)
        #v = round(individual.genotype.genes[max_dimension], digits=2)
        #i = (max_dimension, v)
        i = round(mean(individual.genotype.genes); digits=2)
        push!(info, i)
    end
    sort!(info, by = x -> x[1])
    println("RETIREES_INFO = ", info)
end