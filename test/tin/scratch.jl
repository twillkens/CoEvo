using CoEvo
using Serialization 
using CoEvo.Concrete.Configurations.MaxSolve
using CoEvo.Abstract

function main(vec_vecs)

    G = typeof(vec_vecs[1][1])

    vec_sets = [Set(v) for v in vec_vecs]
    len_each_set = sum([length(s) for s in vec_sets])
    len_all_sets = length(union(vec_sets...))
    println("Length of each set: $len_each_set")
    println("Length of all sets: $len_all_sets")



    all_genotypes = Set{G}()
    prev_genotypes = Set{G}()

    change = 0
    novelty = 0
    generation = 0
    for v in vec_vecs
        s = Set(v)
        change += length(setdiff(s, prev_genotypes))
        novelty += length(setdiff(s, all_genotypes))
        prev_genotypes = s
        all_genotypes = union(all_genotypes, s)
        generation += 1
        println("Generation $generation: Change: $change, Novelty: $novelty")
    end
    println("Total generations: $generation")
    println("Total change: $change")
    println("Total novelty: $novelty")    
end

vec_vecs = deserialize("FSM-DATA/whoa/vec_400.jls")

main(vec_vecs)

vec_vecs_add = deepcopy(vec_vecs)
first_guy = vec_vecs_add[1][1]
push!(vec_vecs_add[end], first_guy)

main(vec_vecs_add)

