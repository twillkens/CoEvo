import numpy as np
from pyclustering.cluster import cluster_visualizer
from pyclustering.cluster.xmeans import xmeans
from pyclustering.cluster.center_initializer import kmeans_plusplus_initializer
from pyclustering.utils import read_sample
from pyclustering.samples.definitions import SIMPLE_SAMPLES

def generate_complex_dataset(num_clusters, points_per_cluster, seed=123):
    np.random.seed(seed)  # Ensure reproducibility
    samples = []

    for i in range(1, num_clusters + 1):
        # Define the center of each cluster
        center = np.random.randint(1, 51, size=2) * i

        # Different variance for each cluster
        variance = 1.0

        # Generate points for each cluster
        for _ in range(points_per_cluster):
            point = center + np.random.randn(2) * variance
            samples.append(point)

    # Add noise (commented out, but included for completeness)
    # for _ in range(int(num_clusters * points_per_cluster * 0.1)):  # 10% noise
    #     samples.append(np.random.randint(1, 501, size=2))

    return samples


# Read sample 'simple3' from file.
sample = read_sample(SIMPLE_SAMPLES.SAMPLE_SIMPLE3)

def perform_xmeans(sample):
    # Prepare initial centers - amount of initial centers defines amount of clusters from which X-Means will
    # start analysis.
    amount_initial_centers = 2
    initial_centers = kmeans_plusplus_initializer(sample, amount_initial_centers).initialize()
    
    # Create instance of X-Means algorithm. The algorithm will start analysis from 2 clusters, the maximum
    # number of clusters that can be allocated is 20.
    xmeans_instance = xmeans(sample, initial_centers, 20)
    xmeans_instance.process()
    
    # Extract clustering results: clusters and their centers
    clusters = xmeans_instance.get_clusters()
    centers = xmeans_instance.get_centers()
    
    # Print total sum of metric errors
    print("Total WCE:", xmeans_instance.get_total_wce())
    
    # Visualize clustering results
    visualizer = cluster_visualizer()
    visualizer.append_clusters(clusters, sample)
    visualizer.append_cluster(centers, None, marker='*', markersize=10)
    visualizer.show()
