using ...CoEvo: Individual
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
