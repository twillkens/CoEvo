module Disco

export get_derived_tests

using DataStructures: SortedDict
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


function get_derived_tests(indiv_tests::SortedDict{Int, Vector{Float64}}, seed::UInt32)
    test_vectors = values(indiv_tests)
    test_matrix = transpose(hcat(test_vectors...))
    centers = center_initializer.kmeans_plusplus_initializer(
        test_matrix, 2, random_state=seed
    ).initialize()
    xmeans_instance = xmeans.xmeans(
        test_matrix, centers, div(length(indiv_tests), 2), random_state=seed
    )
    xmeans_instance.process()
    centers = xmeans_instance.get_centers()
    centers = transpose(centers)
    derived_tests = SortedDict(
        id => center 
        for (id, center) in zip(keys(indiv_tests), eachrow(centers))
    )
    return derived_tests
end

end