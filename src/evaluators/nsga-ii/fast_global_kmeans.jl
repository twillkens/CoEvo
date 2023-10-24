export get_derived_tests, get_fast_global_clustering_result

#using LinearAlgebra


## Calculating Euclidean VDistance
#function eucli_dist(sample, center)
#    return sqrt(sum((sample .- center).^2))
#end
#
## Calculating Squared Euclidean Distance
#function sq_eucli_dist(sample, center)
#    return sum((sample .- center).^2)
#end

#@inline function eucli_dist(sample::Vector{T}, center::Vector{T}) where T
#    return sqrt(dot(sample .- center, sample .- center))
#end
#
#@inline function sq_eucli_dist(sample::Vector{T}, center::Vector{T}) where T
#    return dot(sample .- center, sample .- center)
#end

@inline function eucli_dist(sample::Vector{T}, center::Vector{T}) where T
    @assert length(sample) == length(center)
    s = zero(T)
    @simd for i in eachindex(sample)
        Δ = sample[i] - center[i]
        s += Δ * Δ
    end
    return sqrt(s)
end

@inline function sq_eucli_dist(sample::Vector{T}, center::Vector{T}) where T
    @assert length(sample) == length(center)
    s = zero(T)
    @simd for i in eachindex(sample)
        Δ = sample[i] - center[i]
        s += Δ * Δ
    end
    return s
end

is_power2(num::Int) = (num & (num - 1)) == 0 && num != 0

struct KMeansClusteringResult
    error::Float64
    centroids::Vector{Vector{Float64}}
    cluster_indices::Vector{Vector{Int}}
    clusters::Vector{Vector{Vector{Float64}}}
    bic::Float64
end

function compute_bic(log_likelihood::Float64, k::Int, n::Int)
    return -2 * log_likelihood + k * log(n)
end


function get_kmeans_clustering_result(
    random_number_generator::AbstractRNG,
    samples::Vector{Vector{Float64}}, 
    cluster_count::Int, 
    tolerance::Float64, 
    centroids::Vector{Vector{Float64}},
    maximum_iterations::Int = 500
)
    previous_error = 0.0
    current_error = 0.0
    partition = [Vector{Vector{Float64}}() for _ in 1:cluster_count]
    cluster_indices = [Vector{Int}() for _ in 1:cluster_count]
    current_iteration = 1

    while current_iteration <= maximum_iterations
        # Reset partitions
        foreach(empty!, partition)
        foreach(empty!, cluster_indices)

        # Assign each sample to the closest centroid
        for (sample_index, sample) in enumerate(samples)
            min_distance = eucli_dist(sample, centroids[1])
            assigned_cluster = 1

            for i in 2:cluster_count
                distance = eucli_dist(sample, centroids[i])
                if distance < min_distance
                    min_distance = distance
                    assigned_cluster = i
                end
            end

            push!(cluster_indices[assigned_cluster], sample_index)
            push!(partition[assigned_cluster], sample)
        end


        for (idx, cluster_samples) in enumerate(partition)
            if isempty(cluster_samples)
                centroids[idx] = rand(random_number_generator, samples)
            else
                centroids[idx] = mean(cluster_samples)
            end
        end


        current_error = 0.0
        for idx in 1:cluster_count
            for sample in partition[idx]
                current_error += sq_eucli_dist(sample, centroids[idx])
            end
        end


        # Check for convergence
        if abs(current_error - previous_error) < tolerance
            break
        end

        previous_error = current_error
        current_iteration += 1
    end

    error = round(current_error, sigdigits=4)

    log_likelihood = -0.5 * error
    bic = compute_bic(log_likelihood, cluster_count, length(samples))

    result = KMeansClusteringResult(error, centroids, cluster_indices, partition, bic)

    return result
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
    additional_bucket_keys = [string(next_bucket_index) * "." * string(i) for i in 1:additional_keys_needed]

    # Generate the final list of bucket keys
    bucket_keys = [string(cur_bucket_index) * "." * string(i) for i in (num_bucket_index - additional_keys_needed + 1):num_bucket_index]
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
    current_centroids::Vector{Vector{Float64}}
)
    benefit_value = 0.0
    for (idx, cluster) in enumerate(current_clusters)
        for sample in cluster
            dist_to_current_centroid = sq_eucli_dist(sample, current_centroids[idx])
            dist_to_potential_centroid = sq_eucli_dist(sample, potential_centroid)
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
    random_number_generator::AbstractRNG,
    samples::Vector{Vector{Float64}}, 
    max_clusters::Int = -1,
    tolerance::Float64 = 0.001,
)
    max_clusters = max_clusters == -1 ? length(samples) : max_clusters
    fg = FastGlobal(max_clusters, length(samples[1]))
    initial_centroids = [rand(random_number_generator, samples)]
    current_result = get_kmeans_clustering_result(random_number_generator, samples, 1, tolerance, initial_centroids)

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
            random_number_generator, samples, cluster_size, tolerance, new_centroids
        )
        if next_result.bic >= current_result.bic
            return current_result
        end

        current_result = next_result
    end

    return current_result
end

function get_derived_tests(
    random_number_generator::AbstractRNG, 
    indiv_tests::SortedDict{Int, Vector{Float64}},
    max_clusters::Int = -1
)
    for (id, test_vector) in indiv_tests
        if any(isnan, test_vector)
            println("id: ", id)
            println("test_vector: ", test_vector)
            throw(ErrorException("NaN in test_vector"))
        end
    end
    test_vectors = collect(values(indiv_tests))
    test_columns = [collect(row) for row in eachrow(hcat(test_vectors...))]
    result = get_fast_global_clustering_result(random_number_generator, test_columns, max_clusters)
    derived_test_matrix = hcat(result.centroids...)
    derived_tests = SortedDict(
        id => collect(derived_test)
        for (id, derived_test) in zip(keys(indiv_tests), eachrow(derived_test_matrix))
    )
    return derived_tests
end


#function get_kmeans_clustering_result(
#    random_number_generator::AbstractRNG,
#    samples::Vector{Vector{Float64}}, 
#    cluster_count::Int, 
#    tolerance::Float64, 
#    centroids::Vector{Vector{Float64}},
#    maximum_iterations::Int = 500
#)
#    # Initializing the sum of squared error
#    previous_error = 0.0
#    current_error = 0.0
#    partition = [Vector{Vector{Float64}}() for _ in 1:cluster_count]
#    cluster_indices = [Vector{Int}() for _ in 1:cluster_count]
#    current_iteration = 1
#
#    while current_iteration <= maximum_iterations
#        # Create an empty partition for each centroid
#        partition = [Vector{Vector{Float64}}() for _ in 1:cluster_count]
#        cluster_indices = [Vector{Int}() for _ in 1:cluster_count]
#
#        # Assign each sample to the closest centroid
#        for (sample_index, sample) in enumerate(samples)
#            distances = [eucli_dist(sample, centroid) for centroid in centroids]
#            assigned_cluster = argmin(distances)
#            push!(cluster_indices[assigned_cluster], sample_index)
#            push!(partition[assigned_cluster], sample)
#        end
#
#        # Recompute the centroids of the clusters
#        for (idx, cluster_samples) in enumerate(partition)
#            if isempty(cluster_samples)
#                cluster_samples = [rand(random_number_generator, samples)]  # handle empty clusters
#            end
#            initial_centroid = mean(cluster_samples)
#            centroids[idx] = initial_centroid
#        end
#
#        # Compute the current clustering error
#        current_error = sum(
#            sq_eucli_dist(sample, centroids[idx]) 
#            for idx in 1:cluster_count 
#            for sample in partition[idx]
#        )
#
#        # Check if the change in error is below the tolerance to determine convergence
#        if abs(current_error - previous_error) < tolerance
#            break
#        end
#
#        # Update the error for the next iteration
#        previous_error = current_error
#        current_iteration += 1
#    end
#
#    error = round(current_error, sigdigits=4)
#
#    log_likelihood = -0.5 * error
#    bic = compute_bic(log_likelihood, cluster_count, length(samples))
#
#    result = KMeansClusteringResult(error, centroids, cluster_indices, partition, bic)
#
#    return result
#end
