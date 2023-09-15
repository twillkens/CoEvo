
module PyPacmap
using PyCall

function __init__()
    py"""
    import pacmap
    import pandas as pd
    import numpy as np
    def do_pacmap(filenames, init="pca", apply_pca=True, MN_ratio=0.5, FP_ratio=2.0, 
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
        
        return X_transformed

    """
end
end