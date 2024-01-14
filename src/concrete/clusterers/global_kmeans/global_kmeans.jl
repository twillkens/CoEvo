module GlobalKMeans

export get_derived_tests, get_fast_global_clustering_result
export KMeansClusteringResult, KDNode, FastGlobal
export compute_bic, compute_b_values, compute_b_value
export squared_euclidean_distance, euclidean_distance
export is_power2, build_tree!, generate_power2_keys, generate_non_power2_keys
export get_kmeans_clustering_result
using DataStructures: SortedDict
using StatsBase: mean
using LinearAlgebra: dot
using Random: AbstractRNG, rand


function vector_transpose(vectors::Vector{Vector{Float64}})
    transposed_vectors = [collect(row) for row in eachrow(hcat(vectors...))]
    return transposed_vectors
end

abstract type DistanceMethod end

struct Euclidean <: DistanceMethod end

struct DiscoBinary <: DistanceMethod end

struct DiscoAverage <: DistanceMethod end

@inline function euclidean_distance(sample::Vector{T}, center::Vector{T}) where T
    @assert length(sample) == length(center)
    s = zero(T)
    @simd for i in eachindex(sample)
        Δ = sample[i] - center[i]
        s += Δ * Δ
    end
    return sqrt(s)
end

@inline function squared_euclidean_distance(sample::Vector{T}, center::Vector{T}) where T
    @assert length(sample) == length(center)
    s = zero(T)
    @simd for i in eachindex(sample)
        Δ = sample[i] - center[i]
        s += Δ * Δ
    end
    return s
end

function disco_binary_distance(sample::Vector{Float64}, centroid::Vector{Float64})::Float64
    @assert length(sample) == length(centroid)
    distance = 0.0
    for i in 1:length(sample)
        distance += (sample[i] - round(centroid[i]))^2
    end
    return distance
end

function disco_average_distance(
    sample::Vector{Float64}, centroid::Vector{Float64}, global_averages::Vector{Float64}
)::Float64
    @assert length(sample) == length(centroid) == length(global_averages)
    distance = 0.0
    for i in 1:length(sample)
        threshhold_value = centroid[i] < global_averages[i] ? 0.0 : 1.0
        distance += (sample[i] - threshhold_value)^2
    end
    return distance
end

find_distance(::Euclidean, sample::Vector{Float64}, center::Vector{Float64}, ::Vector{Float64}) = 
    squared_euclidean_distance(sample, center)

find_distance(::DiscoBinary, sample::Vector{Float64}, center::Vector{Float64}, ::Vector{Float64}) =
    disco_binary_distance(sample, center)

find_distance(::DiscoAverage, sample::Vector{Float64}, center::Vector{Float64}, solution_averages::Vector{Float64}) = 
    disco_average_distance(sample, center, solution_averages)


is_power2(num::Int) = (num & (num - 1)) == 0 && num != 0

struct KMeansClusteringResult
    error::Float64
    centroids::Vector{Vector{Float64}}
    cluster_indices::Vector{Vector{Int}}
    clusters::Vector{Vector{Vector{Float64}}}
    bic::Float64
end

# Ensure the input parameters are valid
function validate_parameters(
    samples::Vector{Vector{Float64}}, cluster_count::Int, tolerance::Float64
)::Nothing
    if cluster_count > length(samples)
        throw(ArgumentError("cluster_count cannot be greater than the number of samples"))
    end
    if cluster_count < 1
        throw(ArgumentError("cluster_count cannot be less than 1"))
    end
    if tolerance < 0.0
        throw(ArgumentError("tolerance cannot be less than 0.0"))
    end
    if isempty(samples)
        throw(ArgumentError("samples cannot be empty"))
    end
end

# Reset the clusters
function reset_clusters!(
    partition::Vector{Vector{Vector{Float64}}}, cluster_indices::Vector{Vector{Int}}
)::Nothing
    foreach(empty!, partition)
    foreach(empty!, cluster_indices)
end


function row_means(columns::Vector{Vector{Float64}})
    # First, compute the number of rows and columns
    nrows = length(columns[1])
    ncols = length(columns)

    # Initialize a vector to store the sum of each row
    row_sums = zeros(Float64, nrows)

    # Calculate the sum for each row
    for col in columns
        for i in 1:nrows
            row_sums[i] += col[i]
        end
    end

    # Compute the mean of each row
    row_means = row_sums ./ ncols
    return row_means
end

# Assign samples to the closest centroid
function assign_samples_to_clusters!(
    samples::Vector{Vector{Float64}}, 
    centroids::Vector{Vector{Float64}}, 
    cluster_count::Int, 
    cluster_indices::Vector{Vector{Int}}, 
    partition::Vector{Vector{Vector{Float64}}};
    distance_method::DistanceMethod = Euclidean(),
    solution_averages::Vector{Float64} = Float64[]
)::Nothing
    for (sample_index, sample) in enumerate(samples)
        min_distance = find_distance(distance_method, sample, centroids[1], solution_averages)
        assigned_cluster = 1
        for i in 2:cluster_count
            #distance = euclidean_distance(sample, centroids[i])
            distance = find_distance(distance_method, sample, centroids[i], solution_averages)
            if distance < min_distance
                min_distance = distance
                assigned_cluster = i
            end
        end
        push!(cluster_indices[assigned_cluster], sample_index)
        push!(partition[assigned_cluster], sample)
    end
end

# Update the centroids using the samples assigned to each cluster
function update_centroids!(
    partition::Vector{Vector{Vector{Float64}}}, 
    centroids::Vector{Vector{Float64}}, 
    rng::AbstractRNG, 
    samples::Vector{Vector{Float64}}
)::Nothing
    for (idx, cluster_samples) in enumerate(partition)
        if isempty(cluster_samples)
            centroids[idx] = rand(rng, samples)
        else
            centroids[idx] = mean(cluster_samples)
        end
    end
end

# Compute the clustering error
function compute_clustering_error(
    partition::Vector{Vector{Vector{Float64}}}, 
    centroids::Vector{Vector{Float64}}, 
    cluster_count::Int;
    distance_method::DistanceMethod = Euclidean(),
    solution_averages::Vector{Float64} = Float64[]
)::Float64
    error = 0.0
    for idx in 1:cluster_count
        for sample in partition[idx]
            #error += squared_euclidean_distance(sample, centroids[idx])
            error += find_distance(distance_method, sample, centroids[idx], solution_averages)
        end
    end
    return error
end


function compute_bic(log_likelihood::Float64, k::Int, n::Int)
    return -2 * log_likelihood + k * log(n)
end

function get_kmeans_clustering_result(
    rng::AbstractRNG,
    samples::Vector{Vector{Float64}}, 
    cluster_count::Int, 
    centroids::Vector{Vector{Float64}};
    tolerance::Float64 = 0.001, 
    maximum_iterations::Int = 500,
    args...
)::KMeansClusteringResult
    validate_parameters(samples, cluster_count, tolerance)
    previous_error = 0.0
    current_error = 0.0
    partition = [Vector{Float64}[] for _ in 1:cluster_count]
    cluster_indices = [Int[] for _ in 1:cluster_count]

    for _ in 1:maximum_iterations
        reset_clusters!(partition, cluster_indices)
        assign_samples_to_clusters!(
            samples, centroids, cluster_count, cluster_indices, partition; args...
        )
        update_centroids!(partition, centroids, rng, samples)
        current_error = compute_clustering_error(partition, centroids, cluster_count; args...)
        if abs(current_error - previous_error) < tolerance
            break
        end
        previous_error = current_error
    end

    error = round(current_error, sigdigits=4)
    log_likelihood = -0.5 * error
    bic = compute_bic(log_likelihood, cluster_count, length(samples))
    
    return KMeansClusteringResult(error, centroids, cluster_indices, partition, bic)
end

struct KDNode
    bucket::Vector{Vector{Float64}}
    point::Vector{Float64}
    left::Union{Nothing, KDNode}
    right::Union{Nothing, KDNode}
end

Base.@kwdef mutable struct FastGlobal
    global_data::Dict{String, KDNode}
    partitions::Dict{String, Vector{Vector{Float64}}}
    bucket_count::Int
    sample_dimension::Int

    FastGlobal(bucket_count::Int, sample_dimension::Int) = new(
        Dict(), Dict(), bucket_count, sample_dimension
    )
end
     
function build_tree!(fg::FastGlobal, samples::Vector{Vector{Float64}}; depth=0)
    num_samples = length(samples)
    required_depth = ceil(Int, log(2, fg.bucket_count))
    bucket_index = string(depth) * ".1"

    if num_samples <= 0 || depth > required_depth
        return nothing
    end

    axis = depth % fg.sample_dimension + 1
    sorted_points = sort(samples, by=point -> point[axis])
    count = 1
    while haskey(fg.partitions, bucket_index)
        bucket_index = string(depth) * "." * string(count)
        count += 1
    end

    fg.partitions[bucket_index] = sorted_points
    median_point = num_samples == 1 ? sorted_points[1] : sorted_points[div(num_samples, 2)]

    node = KDNode(
        sorted_points, 
        median_point,
        build_tree!(fg, sorted_points[1:div(num_samples, 2)], depth=depth+1),
        build_tree!(fg, sorted_points[div(num_samples, 2)+1:end], depth=depth+1)
    )
    
    fg.global_data[bucket_index] = node
    return node
end

function generate_power2_keys(fg::FastGlobal)
    cur_bucket_index = ceil(Int, log(2, fg.bucket_count))
    bucket_keys = [string(cur_bucket_index) * "." * string(i) for i in 1:fg.bucket_count]
    return bucket_keys
end

function generate_non_power2_keys(fg::FastGlobal)
    # Get the highest power of 2 less than fg.bucket_count
    cur_bucket_index = floor(Int, log(2, fg.bucket_count))
    num_bucket_index = 2^cur_bucket_index

    # Determine how many keys from the next bucket index we need to add
    additional_keys_needed = fg.bucket_count - num_bucket_index

    # Create a new bucket index
    next_bucket_index = cur_bucket_index + 1

    # Generate the required keys
    additional_bucket_keys = [
        string(next_bucket_index) * "." * string(i) for i in 1:additional_keys_needed
    ]

    # Generate the final list of bucket keys
    bucket_keys = [
        string(cur_bucket_index) * "." * string(i) 
        for i in (num_bucket_index - additional_keys_needed + 1):num_bucket_index
    ]
    append!(bucket_keys, additional_bucket_keys)

    # Check if all keys exist in fg.partitions
    for key in bucket_keys
        if !haskey(fg.partitions, key)
            println("Error: $key not found in fg.partitions!")
        end
    end

    return bucket_keys
end

function compute_b_value(
    potential_centroid::Vector{Float64},
    current_clusters::Vector{Vector{Vector{Float64}}},
    current_centroids::Vector{Vector{Float64}};
    distance_method::DistanceMethod = Euclidean(),
    solution_averages::Vector{Float64} = Float64[]
)
    benefit_value = 0.0
    for (idx, cluster) in enumerate(current_clusters)
        for sample in cluster
            dist_to_current_centroid = find_distance(
                distance_method, sample, current_centroids[idx], solution_averages
            )
            dist_to_potential_centroid = find_distance(
                distance_method, sample, potential_centroid, solution_averages
            )
            benefit_contribution = max(dist_to_current_centroid - dist_to_potential_centroid, 0.0)
            benefit_value += benefit_contribution
        end
    end
    return benefit_value
end

compute_b_values(
    potential_centroids::Vector{Vector{Float64}},
    current_clusters::Vector{Vector{Vector{Float64}}},
    current_centroids::Vector{Vector{Float64}}
) = [
    compute_b_value(potential_centroid, current_clusters, current_centroids) 
    for potential_centroid in potential_centroids
]

compute_b_values(
    potential_centroids::Vector{Vector{Float64}}, result::KMeansClusteringResult
) = [
    compute_b_value(potential_centroid, result.clusters, result.centroids) 
    for potential_centroid in potential_centroids
]

function get_fast_global_clustering_result(
    rng::AbstractRNG,
    samples::Vector{Vector{Float64}};
    max_clusters::Int = -1,
    kwargs...
)
    max_clusters = max_clusters == -1 ? length(samples) : max_clusters
    fg = FastGlobal(max_clusters, length(samples[1]))
    initial_centroids = [rand(rng, samples)]
    current_result = get_kmeans_clustering_result(
        rng, samples, 1, initial_centroids; kwargs...
    )

    build_tree!(fg, samples)

    bucket_keys = is_power2(fg.bucket_count) ? 
        generate_power2_keys(fg) : 
        generate_non_power2_keys(fg)
    potential_centroids = [mean(fg.partitions[key]) for key in bucket_keys]

    for cluster_size in 2:max_clusters
        b_values = compute_b_values(potential_centroids, current_result)
        new_centroid_idx = argmax(b_values)
        new_centroids = Vector{Float64}[
            current_result.centroids ; [potential_centroids[new_centroid_idx]]
        ]
        next_result = get_kmeans_clustering_result(
            rng, samples, cluster_size, new_centroids; kwargs...
        )
        if next_result.bic >= current_result.bic
            return current_result
        end

        current_result = next_result
    end

    return current_result
end

function get_derived_tests(
    rng::AbstractRNG, 
    indiv_tests::SortedDict{Int, Vector{Float64}},
    max_clusters::Int,
    distance_method::DistanceMethod
)
    for (id, test_vector) in indiv_tests
        if any(isnan, test_vector)
            println("id: ", id)
            println("test_vector: ", test_vector)
            throw(ErrorException("NaN in test_vector"))
        end
    end
    test_vectors = collect(values(indiv_tests))
    solution_averages = [mean(test_vector) for test_vector in test_vectors]
    test_columns = [collect(row) for row in eachrow(hcat(test_vectors...))]
    result = get_fast_global_clustering_result(
        rng, test_columns; 
        solution_averages = solution_averages,
        max_clusters = max_clusters, 
        distance_method = distance_method
    )
    derived_test_matrix = hcat(result.centroids...)
    derived_tests = SortedDict{Int, Vector{Float64}}(
        id => collect(derived_test)
        for (id, derived_test) in zip(keys(indiv_tests), eachrow(derived_test_matrix))
    )
    return derived_tests
end

const DISTANCE_METHODS = Dict(
    "euclidean" => Euclidean(),
    "disco_binary" => DiscoBinary(),
    "disco_average" => DiscoAverage()
)

function get_derived_tests(
    rng::AbstractRNG, 
    indiv_tests::SortedDict{Int, Vector{Float64}},
    max_clusters::Int = -1,
    distance_method::String = "euclidean"
)
    return get_derived_tests(
        rng, indiv_tests, max_clusters, DISTANCE_METHODS[distance_method]
    )
end

end