import pacmap
import numpy as np
import matplotlib.pyplot as plt
import sys
import pandas as pd

# loading preprocessed coil_20 dataset
# you can change it with any dataset that is in the ndarray format, with the shape (N, D)
# where N is the number of samples and D is the dimension of each sample
#X = np.genfromtxt('addressa.csv', delimiter=',', skip_header=1)
##X = X.reshape(X.shape[0], -1)
#
## initializing the pacmap instance
## Setting n_neighbors to "None" leads to a default choice shown below in "parameter" section
#embedding = pacmap.PaCMAP(n_components=2, n_neighbors=None, MN_ratio=0.5, FP_ratio=2.0, verbose=True,) 
#
## fit the data (The index of transformed data corresponds to the index of the original data)
#X_transformed = embedding.fit_transform(X[::10], init="pca")
#
## visualize the embedding
#fig, ax = plt.subplots(1, 1, figsize=(6, 6))
#ax.scatter(X_transformed[:, 0], X_transformed[:, 1],) #cmap="Spectral", c=y, s=0.6)
#plt.show()

def do_pacmap(filenames, savefile, init="pca", apply_pca=True):
    # Read and concatenate data from all files
    frames = [pd.read_csv(filename) for filename in filenames]
    X = pd.concat(frames).values

    # Initialize the pacmap instance
    embedding = pacmap.PaCMAP(n_components=2, n_neighbors=None, MN_ratio=0.5, FP_ratio=2.0, verbose=True, apply_pca=apply_pca) 

    # Transform the data
    X_transformed = embedding.fit_transform(X, init=init)
    
    # Save the transformed data to a file
    np.savetxt(savefile, X_transformed, delimiter=",")
    
    return X_transformed

def do_plot(X):
# Define the cutoffs
    first_cutoff = min(2000, len(X))
    second_cutoff = min(4000, len(X))

    # Split the original data into three groups
    X_blue = X[:first_cutoff]
    X_red = X[first_cutoff:second_cutoff]
    X_grey = X[second_cutoff:]

    # Initialize the pacmap instance

    # Transform each group separately

    # Generate alpha values for fading effect
    alpha_blue = np.linspace(1, 0, len(X_blue))
    alpha_red = np.linspace(1, 0, len(X_red))

    # Visualize the embedding
    fig, ax = plt.subplots(1, 1, figsize=(8, 8))

    # Plot each group of points with its own color and fading transparency
    for i in range(len(X_blue)):
        ax.scatter(X_blue[i, 0], X_blue[i, 1], color='blue', s=5, alpha=alpha_blue[i])

    for i in range(len(X_red)):
        ax.scatter(X_red[i, 0], X_red[i, 1], color='red', s=5, alpha=alpha_red[i])

    ax.scatter(X_grey[:, 0], X_grey[:, 1], color='grey', s=5, alpha=0.05)

    # Add grid, title, and labels
    ax.grid(True)
    plt.title('PaCMAP Embedding', fontsize=18)
    plt.xlabel('Component 1', fontsize=14)
    plt.ylabel('Component 2', fontsize=14)

    plt.show()


if __name__ == "__main__":
    fname = sys.argv[1]
    X = np.genfromtxt(fname, delimiter=',', skip_header=1,)
    do_plot(X)