export IdentityReplacer, TruncationReplacer, GenerationalReplacer, DiscoReplacer
export CommaReplacer

# Returns the population of veterans without change
struct IdentityReplacer <: Replacer end

function(r::IdentityReplacer)(::AbstractRNG, pop::Vector{<:Individual}, ::Vector{<:Individual})
    pop
end

# Returns the best npop individuals from both the population and children
Base.@kwdef struct TruncationReplacer <: Replacer
    npop::Int
end

function(r::TruncationReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    sort([pop ; children], by = i -> fitness(i), rev = true)[1:r.npop]
end

# Replaces the population with the children, keeping the best n_elite individuals from the
# population
Base.@kwdef struct GenerationalReplacer <: Replacer
    n_elite::Int = 0
    reverse::Bool = false
end

function(r::GenerationalReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    if length(children) == 0
        return pop
    end
    elites = sort(pop, by = i -> fitness(i), rev = r.reverse)[1:r.n_elite]
    n_children = length(pop) - r.n_elite
    children = sort(children, by = i -> fitness(i), rev = r.reverse)[1:n_children]
    pop = [elites; children]
    pop

end

Base.@kwdef struct CommaReplacer <: Replacer
    npop::Int
end

function(r::CommaReplacer)(
    ::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    children = length(children) == 0 ? pop : children
    sort(children, by = i -> fitness(i), rev = true)[1:r.npop]
end


function(r::Replacer)(rng::AbstractRNG, species::Species)
    r(rng, collect(values(species.pop)), collect(values(species.children)))
end

using PyCall

const center_initializer = PyNULL()
const kmeans = PyNULL()
const xmeans = PyNULL()

function __init__()
    mod = "pyclustering.cluster.center_initializer"
    copy!(center_initializer, pyimport_conda(mod, "pyclustering", "conda-forge"))
    mod = "pyclustering.cluster.kmeans"
    copy!(kmeans, pyimport_conda(mod, "pyclustering", "conda-forge"))
    mod = "pyclustering.cluster.xmeans"
    copy!(xmeans, pyimport_conda(mod, "pyclustering", "conda-forge"))
end

Base.@kwdef struct DiscoReplacer <: Replacer
    npop::Int = 50
    xmeans_seed::UInt32 = UInt32(0)
end

function(r::DiscoReplacer)(
    rng::AbstractRNG, pop::Vector{<:Individual}, children::Vector{<:Individual}
)
    pop = [pop ; children] 
    seed = r.xmeans_seed == 0 ?  rand(rng, UInt32) : r.xmeans_seed
    set_derived_tests(pop, seed)
end


function vecvec_to_matrix(vecvec)
     dim1 = length(vecvec)
     dim2 = length(vecvec[1])
     my_array = zeros(Float32, dim1, dim2)
     for i in 1:dim1
         for j in 1:dim2
             my_array[i,j] = vecvec[i][j]
         end
     end
     return my_array
 end

function set_derived_tests(pop::Vector{<:Individual}, seed::UInt32)
    ys = [sort(collect(values(indiv.rdict))) for indiv in pop]
    m = vecvec_to_matrix(ys)
    m = transpose(m)
    centers = center_initializer.kmeans_plusplus_initializer(m, 2, random_state=seed).initialize()
    xmeans_instance = xmeans.xmeans(m, centers, div(length(pop), 2), random_state=seed)
    xmeans_instance.process()
    centers = xmeans_instance.get_centers()
    centers = transpose(centers)
    for (indiv, center) in zip(pop, eachrow(centers))
        indiv.derived_tests = center
    end
    pop
    #clusters = Vector{Vector{String}}()
    #numstring_dict = Dict(i => k for (i, k) in enumerate(sort(collect(keys(pop[1].rdict)))))
    #for numcluster in xmeans_instance.get_clusters()
    #    stringcluster = Vector{String}()
    #    for num in numcluster
    #        push!(stringcluster, numstring_dict[num + 1])
    #    end
    #    push!(clusters, stringcluster)
    #end
    #clusters
end