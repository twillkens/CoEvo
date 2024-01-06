import numpy as np

def euclidean_distance(point1, point2):
    """Calculate Euclidean distance between two points."""
    return np.sqrt(np.sum((point1 - point2) ** 2))

def bayesian_information_criterion(clusters, centers, data_points):
    """
    Calculates the Bayesian Information Criterion for the given clusters and centers.
    
    :param clusters: List of clusters, each cluster is a list of indices of data points in the cluster.
    :param centers: List of centers of the clusters.
    :param data_points: List of data points.
    :return: BIC value.
    """
    K = len(centers)
    N = sum(len(cluster) for cluster in clusters)
    dimension = len(data_points[0])
    sigma_sqrt = 0.0
    print("K:", K)
    print("N:", N)
    print("dimension:", dimension
        )

    # Calculate sum of squared distances from points to their cluster centers
    for index_cluster, cluster in enumerate(clusters):
        center = centers[index_cluster]
        for index_point in cluster:
            point = data_points[index_point]
            sigma_sqrt += euclidean_distance(point, center) ** 2

    print("sigma_sqrt:", sigma_sqrt)
    if N - K > 0:
        sigma_sqrt /= (N - K)
        print("sigma_sqrt:", sigma_sqrt)
        p = (K - 1) + dimension * K + 1
        print("p:", p)
        scores = []

        for cluster in clusters:
            n = len(cluster)
            print("n:", n)
            if n > 0:
                sigma_multiplier = float('-inf') if sigma_sqrt <= 0.0 else dimension * 0.5 * np.log(sigma_sqrt)
                print("sigma_multiplier:", sigma_multiplier)
                arg1 = n * np.log(n)
                arg2 = n * np.log(N)
                #L = n * np.log(n) - n * np.log(N) - n * 0.5 * np.log(2 * np.pi) - n * sigma_multiplier - (n - K) * 0.5
                L = n * np.log(n / N) - n * 0.5 * np.log(2 * np.pi) - n * sigma_multiplier - (n - K) * 0.5
                print("L:", L)
                scores.append(L - p * 0.5 * np.log(N))
            else:
                scores.append(float('-inf'))

        print("scores:", scores)
        return sum(scores)
    else:
        return float('-inf')

# Example usage
clusters = [[0, 1], [2, 3]]
centers = np.array([[1.0, 2.0], [3.0, 4.0]])
data_points = np.array([[1, 2], [1.5, 2.5], [3, 4], [3.5, 4.5]])
bic = bayesian_information_criterion(clusters, centers, data_points)
print("BIC:", bic)
