import pacmap
import numpy as np
import matplotlib.pyplot as plt
import sys
import pandas as pd
from mpl_toolkits.mplot3d import Axes3D

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

def do_pacmap(filenames, savefile, init="pca", apply_pca=True, MN_ratio=0.5, FP_ratio=2.0, 
              verbose=True, num_iters=450, n_components=2):
    # Read and concatenate data from all files
    frames = [pd.read_csv(filename) for filename in filenames]
    X = pd.concat(frames).values

    # Initialize the pacmap instance
    embedding = pacmap.PaCMAP(n_components=n_components, n_neighbors=None, MN_ratio=MN_ratio, 
                              FP_ratio=FP_ratio, verbose=verbose, apply_pca=apply_pca, 
                              num_iters=num_iters) 

    # Transform the data
    X_transformed = embedding.fit_transform(X, init=init)
    
    # Save the transformed data to a file
    np.savetxt(savefile, X_transformed, delimiter=",", fmt = "%f")
    
    return X_transformed

# def do_plot(X, cutoffs, xlim=[-15.0, 10.0], ylim=[-15.0, 5.0]):
#     # Add the length of X to the cutoffs list to include any remaining data
#     #cutoffs.append(len(X))
#     
#     # Generate a list of data segments and corresponding alphas based on the cutoffs
#     data_segments = [X[cutoffs[i-1] if i > 0 else 0:cutoffs[i]] for i in range(len(cutoffs))]
#     alphas = [np.linspace(0, 1, len(segment)) for segment in data_segments]
#     
#     # Initialize the figure
#     fig, ax = plt.subplots(1, 1, figsize=(8, 8))
# 
#     # Plot each data segment with its own color and fading transparency
#     for i, (data, alpha) in enumerate(zip(data_segments, alphas)):
#         color = next(ax._get_lines.prop_cycler)['color']
#         for j in range(len(data)):
#             ax.scatter(data[j, 0], data[j, 1], color=color, s=5, alpha=alpha[j])
#     
#     # Add grid, title, and labels
#     ax.grid(True)
#     plt.title('PaCMAP Embedding', fontsize=18)
#     plt.xlabel('Component 1', fontsize=14)
#     plt.ylabel('Component 2', fontsize=14)
#     plt.xlim(xlim)
#     plt.ylim(ylim)
# 
#     plt.show()

def do_plot(X, cutoffs, xlim=[-15.0, 10.0], ylim=[-15.0, 5.0], fname = "addressa.png", dpi=400, plot_line = False):
    # Generate a list of data segments and corresponding alphas based on the cutoffs
    data_segments = [X[cutoffs[i-1] if i > 0 else 0:cutoffs[i]] for i in range(len(cutoffs))]
    alphas = [np.linspace(0, 1, len(segment)) for segment in data_segments]
    
    # Initialize the figure
    fig, ax = plt.subplots(1, 1, figsize=(8, 8))

    # Plot each data segment with its own color and fading transparency
    for i, (data, alpha) in enumerate(zip(data_segments, alphas)):
        color = next(ax._get_lines.prop_cycler)['color']
        for j in range(len(data)-1):  # subtract 1 so we don't go out of bounds
            ax.scatter(data[j, 0], data[j, 1], color=color, s=5, alpha=alpha[j])
            if plot_line:
                ax.plot(data[j:j+2, 0], data[j:j+2, 1], color=color, linewidth=1, alpha=alpha[j])
    
        ax.plot([], [], color=color, label=f'Grow-{i+1}')
        
    # Add grid, title, and labels
    ax.grid(True)
    plt.title('ADDRESSA Prototype', fontsize=18)
    plt.xlabel('Component 1', fontsize=14)
    plt.ylabel('Component 2', fontsize=14)
    plt.xlim(xlim)
    plt.ylim(ylim)
    plt.legend()

    plt.draw()
    plt.savefig(fname, dpi=dpi)
    plt.show()


def do_plot_3d(X, cutoffs, xlim=[-15.0, 10.0], ylim=[-15.0, 5.0], zlim=[-15.0, 10.0], fname = "addressa_3d.png", dpi=400):
    # Generate a list of data segments and corresponding alphas based on the cutoffs
    data_segments = [X[cutoffs[i-1] if i > 0 else 0:cutoffs[i]] for i in range(len(cutoffs))]
    alphas = [np.linspace(0, 1, len(segment)) for segment in data_segments]

    # Initialize the figure
    fig = plt.figure(figsize=(8, 8))
    ax = fig.add_subplot(111, projection='3d')

    # Plot each data segment with its own color and fading transparency
    for i, (data, alpha) in enumerate(zip(data_segments, alphas)):
        color = next(ax._get_lines.prop_cycler)['color']
        for j in range(len(data)-1):  # subtract 1 so we don't go out of bounds
            ax.scatter(data[j, 0], data[j, 1], data[j, 2], color=color, s=5, alpha=alpha[j])
            ax.plot(data[j:j+2, 0], data[j:j+2, 1], data[j:j+2, 2], color=color, linewidth=1, alpha=alpha[j])
        
        ax.plot([], [], [], color=color, label=f'Grow-{i+1}')

    # Add grid, title, and labels
    ax.grid(True)
    ax.set_title('ADDRESSA Prototype', fontsize=18)
    ax.set_xlabel('Component 1', fontsize=14)
    ax.set_ylabel('Component 2', fontsize=14)
    ax.set_zlabel('Component 3', fontsize=14)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_zlim(zlim)
    ax.legend()

    plt.draw()
    plt.savefig(fname, dpi=dpi)
    plt.show()

import matplotlib.animation as animation

from itertools import count
def do_anim(file="grow_emb.csv", cutoffs=[1000, 2000, 3000, 4000, 5000], 
            xlim=[-5, 8], ylim=[5, 18], fname = "addressa.mp4", dpi=150):
    # Generate a list of data segments based on the cutoffs
    X = np.loadtxt(file, delimiter=',')
    data_segments = [X[cutoffs[i-1] if i > 0 else 0:cutoffs[i]] for i in range(len(cutoffs))]
    l1, l2, l3, l4, l5 = data_segments

    # Creating a blank window for the animation 
 
# subplots() function you can draw
# multiple plots in one figure
    fig, axes = plt.subplots(nrows=1, ncols=1, figsize=(10, 5))
    
    # set limit for x and y axis
    #axes.set_xlim(xlim[0], xlim[1])
    #axes.set_ylim(ylim[0], ylim[1])
    
    # style for plotting line
    plt.style.use("ggplot")
    
    # create 5 list to get store element
    # after every iteration
    y1, y2, y3, y4, y5 = [], [], [], [], []
    x1, x2, x3, x4, x5 = [], [], [], [], []
    print(l1.shape)
    
    def animate(i):
        print(i)
        x1.append((l1[i, 0]))
        y1.append((l1[i, 1]))
        x2.append((l2[i, 0]))
        y2.append((l2[i, 1]))
        x3.append((l3[i, 0]))
        y3.append((l3[i, 1]))
        x4.append((l4[i, 0]))
        y4.append((l4[i, 1]))
        x5.append((l5[i, 0]))
        y5.append((l5[i, 1]))
        # y2.append((l2[i]))
        # y3.append((l3[i]))
        # y4.append((l4[i]))
        # y5.append((l5[i]))
    
        axes.plot(x1, y1, color="red")
        axes.plot(x2, y2, color="orange")
        axes.plot(x3, y3, color="blue")
        axes.plot(x4, y4, color="green")
        axes.plot(x5, y5, color="purple")
    
    
    # set ani variable to call the
    # function recursively
    anim = animation.FuncAnimation(fig, animate, interval=30, frames=1000)
    anim.save("addressa.mp4", writer=animation.FFMpegWriter(fps=30))

def generate_random_uniform_dataframe(num_rows, num_cols, min_, max_):
    data = np.random.uniform(min_, max_, (num_rows, num_cols))
    
    # Create column names
    col_names = ['x' + str(i+1) for i in range(num_cols)]
    
    df = pd.DataFrame(data, columns=col_names)
    
    return df

def generate_random_normal_dataframe(num_rows, num_cols, mean, std_dev):
    data = np.random.normal(mean, std_dev, (num_rows, num_cols))
    
    # Create column names
    col_names = ['x' + str(i+1) for i in range(num_cols)]
    
    df = pd.DataFrame(data, columns=col_names)
    
    return df
# def do_plot(X):
# # Define the cutoffs
#     first_cutoff = min(1000, len(X))
#     second_cutoff = min(2000, len(X))
# 
#     # Split the original data into three groups
#     X_blue = X[:first_cutoff]
#     X_red = X[first_cutoff:second_cutoff]
#     X_grey = X[second_cutoff:]
# 
#     # Initialize the pacmap instance
# 
#     # Transform each group separately
# 
#     # Generate alpha values for fading effect
#     alpha_blue = np.linspace(0, 1, len(X_blue))
#     alpha_red = np.linspace(0, 1, len(X_red))
# 
#     # Visualize the embedding
#     fig, ax = plt.subplots(1, 1, figsize=(8, 8))
# 
#     # Plot each group of points with its own color and fading transparency
#     for i in range(len(X_blue)):
#         ax.scatter(X_blue[i, 0], X_blue[i, 1], color='blue', s=5, alpha=alpha_blue[i])
# 
#     for i in range(len(X_red)):
#         ax.scatter(X_red[i, 0], X_red[i, 1], color='red', s=5, alpha=alpha_red[i])
# 
#     ax.scatter(X_grey[:, 0], X_grey[:, 1], color='grey', s=5, alpha=0.1)
# 
#     # Add grid, title, and labels
#     ax.grid(True)
#     plt.title('PaCMAP Embedding', fontsize=18)
#     plt.xlabel('Component 1', fontsize=14)
#     plt.ylabel('Component 2', fontsize=14)
# 
#     plt.show()


if __name__ == "__main__":
    fname = sys.argv[1]
    X = np.genfromtxt(fname, delimiter=',', skip_header=1,)
    do_plot(X)