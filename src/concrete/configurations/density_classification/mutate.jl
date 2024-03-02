export PerBitMutator, mutate!
using Random  # Ensure the Random module is used for shuffle!
using Distributions
using ....Abstract
import ....Interfaces: recombine
using ....Interfaces
using ...Individuals.Dodo: DodoIndividual

function generate_variations(bitstring)
    # Original
    O = bitstring
    
    # Reversed
    R = reverse(bitstring)
    
    # Inverted Original
    IO = [1 - bit for bit in O]
    
    # Inverted Reversed
    IR = [1 - bit for bit in R]
    
    # Function to generate Midpoint Mirror (applied to both original and reversed, and their inversions)
    function midpoint_mirror(bs)
        midpoint = div(length(bs), 2)
        if length(bs) % 2 == 0
            return vcat(bs[1:midpoint], reverse(bs[1:midpoint]))
        else
            return vcat(bs[1:midpoint+1], reverse(bs[1:midpoint]))
        end
    end
    
    # Midpoint Mirror for Original and Reversed
    MM_O = midpoint_mirror(O)
    MM_R = midpoint_mirror(R)
    
    # Since MM_IO == IMM_O and MM_IR == IMM_R, we don't generate MM_IO and MM_IR explicitly
    # Instead, we generate IMM_O and IMM_R which are the inverted mirrors of MM_O and MM_R respectively
    IMM_O = [1 - bit for bit in MM_O]  # This also covers MM_IO
    IMM_R = [1 - bit for bit in MM_R]  # This also covers MM_IR
    
    # Note: MM_O and IMM_O together cover the cases for MM_IO and IMM_IO due to the commutative property
    # Similarly, MM_R and IMM_R cover the cases for MM_IR and IMM_IR
    
    return [R, IO, IR, MM_O, IMM_O, MM_R, IMM_R]
end

function mutate_per_bit!(genes::Vector, flip_chance::Float64, rng::AbstractRNG = Random.GLOBAL_RNG)
    for i in eachindex(genes)
        if rand(rng) < flip_chance
            genes[i] = 1 - genes[i]
        end
    end
end

function get_exponential_window_size(max_size::Int, rng::AbstractRNG)
    # Define the scale of the distribution to better fit the desired window size range
    scale_factor = max_size / 5  # Adjust the scale factor to control distribution spread
    
    # Create an exponential distribution with mean = scale_factor
    exp_dist = Exponential(scale_factor)
    
    while true
        # Generate a window size from the exponential distribution
        window_size = round(Int, rand(rng, exp_dist))
        
        # If the window size is within the valid range, return it
        if 1 <= window_size <= max_size
            return window_size
        end
        # Otherwise, regenerate the window size
    end
end

function mutate_per_bit(
    genes::Vector, flip_chance::Float64 = 0.05, rng::AbstractRNG = Random.GLOBAL_RNG
) 
    new_genes = copy(genes)
    flip_chance = 0.01 * get_exponential_window_size(10, rng)
    mutate_per_bit!(new_genes, flip_chance, rng)
    return new_genes
end

function get_permutations(
    genes::T, n_mutants::Int, flip_chance::Float64 = 0.05, rng::AbstractRNG = Random.GLOBAL_RNG
) where T <: Vector
    all_variations = Set{T}()
    original_variations = generate_variations(genes)
    union!(all_variations, original_variations)
    while length(all_variations) < (n_mutants * 8) - 1
        mutant_genotype = mutate_per_bit(genes, flip_chance, rng)
        push!(all_variations, mutant_genotype)
        mutant_variations = generate_variations(mutant_genotype)
        shuffle!(rng, mutant_variations)
        n_add = n_mutants - length(all_variations)
        to_add = unique(mutant_variations[1:n_add])
        union!(all_variations, to_add)
    end
    return collect(all_variations)
end

Base.@kwdef struct PermutationRecombiner <: Recombiner
    n_mutants::Int = 4
    flip_chance::Float64 = 0.05
end

using ...Genotypes.Vectors: BasicVectorGenotype

function recombine(
    recombiner::PermutationRecombiner, 
    parents::Vector{I}, 
    reproducer::Reproducer, 
    state::State
) where {I <: Individual}
    genotypes = []
    for parent in parents
        permutations = get_permutations(
            parent.genotype.genes, recombiner.n_mutants, recombiner.flip_chance, state.rng
        )
        for p in permutations
            push!(genotypes, (parent, p))
        end
    end
    children = [
        create_child([parent], BasicVectorGenotype(genotype), reproducer, state) 
        for (parent, genotype) in genotypes
    ]
    child_ids = [child.id for child in children]
    parent_ids = [parent.id for parent in parents]
    if length([child_ids ; parent_ids]) != length(Set([child_ids ; parent_ids]))
        println("Parents: $parent_ids")
        println("Children: $child_ids")
        throw(ArgumentError("PERM: Duplicate IDs found in the parents and children"))
    end
    #n_expected = (length(parents) * (recombiner.n_mutants * 8)) - length(parents)
    #if length(children) != n_expected
    #    throw(ArgumentError("Expected $n_expected children, but got $(length(children))"))
    #end
    return children
end

function create_child(
    parents::Vector{<:DodoIndividual}, genotype::Genotype, reproducer::Reproducer, state::State
)
    id = step!(state.individual_id_counter)
    parent_ids = [parent.id for parent in parents]
    phenotype = create_phenotype(reproducer.phenotype_creator, id, genotype)
    return DodoIndividual(id, parent_ids, 0, 1, genotype, phenotype)
end

Base.@kwdef struct PerBitMutator <: Mutator
    flip_chance::Float64 = 0.02
end

function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
    mutate_per_bit!(genotype.genes, mutator.flip_chance, state.rng)
end


#function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
#    genes = genotype.genes
#    if rand(state.rng) < 0.1
#        # 10% chance to perform bit flips
#        for i in eachindex(genes)
#            if rand(state.rng) < mutator.flip_chance
#                genes[i] = rand(state.rng) < 0.5 ? 0 : 1
#            end
#        end
#    else
#        # 90% chance to shuffle a window within the genes
#        window_size = rand(1:length(genes))  # Determine the window size
#        start_index = rand(1:(length(genes) - window_size + 1))  # Start index of the window
#        end_index = start_index + window_size - 1  # End index of the window
#
#        # Select the window and shuffle it
#        window = genes[start_index:end_index]
#        shuffle!(state.rng, window)  # Shuffle using the provided RNG for consistency
#
#        # Place the shuffled window back
#        genes[start_index:end_index] = window
#    end
#end
#

#function mutate!(mutator::PerBitMutator, genotype::BasicVectorGenotype, state::State)
#    #noise_vector = randn(rng, T, length(genotype))
#    genes = genotype.genes
#    for i in eachindex(genes)
#        if rand(state.rng) < mutator.flip_chance
#            genes[i] = rand(state.rng) < 0.5 ? 0 : 1
#        end
#    end
#end
