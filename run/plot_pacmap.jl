using Plots
using DelimitedFiles
using Statistics


using GraphRecipes
using GraphNeuralNetworks, Colors

function graph_label_colorants(g::GNNGraph)
    # Generate color maps
    #colormap = ["#E74C3C", "#9B59B6", "#3498DB", "#1ABC9C", "#27AE60", "#F1C40F", "#E67E22", "#BA4A00", "#EC7063", "#AF7AC5", "#5499C7", "#48C9B0", "#52BE80", "#F4D03F", "#F39C12"]
    colormap = ["red", "green", "blue", "orange", "purple", "black", "saddlebrown"]

    colormap = [parse(Colorant, color) for color in colormap]

    # Extract labels
    node_labels = [g.ndata.x[:, i] for i in 1:g.num_nodes]
    edge_labels = [g.edata.e[:, i] for i in 1:g.num_edges]

    # Get indices of ones
    node_indices = [findfirst(==(1.0), label) for label in node_labels]
    edge_indices = [findfirst(==(1.0), label) for label in edge_labels]

    # Create color vectors and dictionaries
    node_colors = [colormap[node_indices[i][1]] for i in 1:length(node_indices)]
    
    # Create a dictionary that maps (src, tgt) to edge color,
    # taking care to add an edge color only if it's not already in the dictionary.
    edge_colorants = Dict()
    for (i, (src, tgt)) in enumerate(zip(edge_index(g)...))
        haskey(edge_colorants, (src, tgt)) || (edge_colorants[(src, tgt)] = colormap[edge_indices[i][1]])
    end

    # Create adjacency matrix with maximum one edge per node pair
    adj_mat = zeros(Int, g.num_nodes, g.num_nodes)
    for (src, tgt) in keys(edge_colorants)
        adj_mat[src, tgt] = 1
    end

    return adj_mat, node_colors, edge_colorants
end

function plot_colored_graph(g::GNNGraph; plot_title::String = "FSM")
    # Get adjacency matrix and color vectors
    adj_mat, node_colors, edge_colorants = graph_label_colorants(g)

    # Plot the graph
    graphplot(
        adj_mat, 
        nodecolor=node_colors, 
        edgecolor=edge_colorants, 
        method=:shell, 
        title=plot_title,
    )
end

# You can then call this function like this:

function do_anim(;file="data/new_addressa/grow_emb.csv", cutoffs=[1000, 2000, 3000, 4000, 5000], 
        xlim=(-5, 8), ylim=(5, 18), fname="addressa-new.mp4", dpi=150)
    # Load the data
    X = readdlm(file, ',')
    l = @layout [a ; b c d e f ]
    
    # Generate a list of data segments based on the cutoffs
    data_segments = [X[(i == 1 ? 1 : cutoffs[i-1]+1):cutoffs[i], :] for i in 1:length(cutoffs)]
    l1, l2, l3, l4, l5 = data_segments

    # Create a plot
    #plt = plot(xlim=xlim, ylim=ylim, size=(700, 500))
    colors = [:red, :orange, :blue, :green, :purple]
    fsms1 = load_graphs_vec("data/growlink1/")
    fsms2 = load_graphs_vec("data/growlink2/")
    fsms3 = load_graphs_vec("data/growlink3/")
    fsms4 = load_graphs_vec("data/growlink4/")
    fsms5 = load_graphs_vec("data/growlink5/")


    anim = @animate for i ∈ 1:1000
        println(i)
            p = plot()
            for (li, color) in zip((l1, l2, l3, l4, l5), colors)
                if i <= size(li, 1)
                    p = plot!(p, li[1:i, 1], li[1:i, 2], color=color, lw=2, legend=false)
                end
            end
            plot(
                p, 
                plot_colored_graph(fsms1[i], plot_title="FSM1"),
                plot_colored_graph(fsms2[i], plot_title="FSM2"),
                plot_colored_graph(fsms3[i], plot_title="FSM3"),
                plot_colored_graph(fsms4[i], plot_title="FSM4"),
                plot_colored_graph(fsms5[i], plot_title="FSM5"),
                plot_title="ADDRESSA-Grow: Generation $i", 
                dpi=dpi, 
                layout = l,
                size=(1200, 900)
            )
    end
    
    # Save the animation
    gif(anim, fname, fps = 30)
end

function do_anim_pair(;
    cutoffs=[1000, 2000], 
    dpi=150, 
    fsms1_title = "host",
    fsms2_title = "parasite",
    eco = "comp",
    trial = 2,
    prune = "full",
    n_gen = 1000,
)
    # Load the data
    xfile = "$eco-$trial-$prune.csv"
    X = readdlm(xfile, ',')
    l = @layout [a ; b c ]
    
    # Generate a list of data segments based on the cutoffs
    data_segments = [X[(i == 1 ? 1 : cutoffs[i-1]+1):cutoffs[i], :] for i in 1:length(cutoffs)]
    l1, l2, = data_segments

    # Create a plot
    #plt = plot(xlim=xlim, ylim=ylim, size=(700, 500))
    colors = [:red, :orange, :blue, :green, :purple]
    fsms1_dir = "paperdata/$eco-$trial/$fsms1_title-$prune/"
    fsms2_dir = "paperdata/$eco-$trial/$fsms2_title-$prune/"
    fsms1 = load_graphs_vec(fsms1_dir)
    fsms2 = load_graphs_vec(fsms2_dir)


    anim = @animate for i ∈ 1:n_gen
        println(i, " ", fsms1[i].num_nodes, " ", fsms2[i].num_nodes )
        start = max(1, i - 50)
        start = 1
        p = plot()
        for (li, color) in zip((l1, l2,), colors)
            if i <= size(li, 1)
                p = plot!(p, li[start:i, 1], li[start:i, 2], color=color, lw=2, legend=false, alpha=0.5)
            end
        end
        plot(
            p, 
            plot_colored_graph(fsms1[i], plot_title=fsms1_title),
            plot_colored_graph(fsms2[i], plot_title=fsms2_title),
            plot_title="ADDRESSA-$eco-$trial-$prune: Generation $i", 
            dpi=dpi, 
            layout = l,
            size=(1200, 900)
        )
    end
    
    fname = "addressa-$eco-$trial-$prune.mp4"
    # Save the animation
    gif(anim, fname, fps = 30)
end

function do_anim_tri(;
    cutoffs=[1000, 2000, 3000], 
    dpi=150, 
    fsms1_title = "host",
    fsms2_title = "parasite",
    fsms3_title = "symbiote",
    eco = "3-Mix",
    trial = 1,
    prune = "full",
    n_gen = 1000,
)
    # Load the data
    xfile = "$eco-$trial-$prune.csv"
    X = readdlm(xfile, ',')
    l = @layout [a ; b c d]
    
    # Generate a list of data segments based on the cutoffs
    data_segments = [X[(i == 1 ? 1 : cutoffs[i-1]+1):cutoffs[i], :] for i in 1:length(cutoffs)]
    l1, l2, l3, = data_segments

    # Create a plot
    #plt = plot(xlim=xlim, ylim=ylim, size=(700, 500))
    colors = [:red, :orange, :blue, :green, :purple]
    fsms1_dir = "paperdata/$eco-$trial/$fsms1_title-$prune/"
    fsms2_dir = "paperdata/$eco-$trial/$fsms2_title-$prune/"
    fsms3_dir = "paperdata/$eco-$trial/$fsms3_title-$prune/"
    fsms1 = load_graphs_vec(fsms1_dir)
    fsms2 = load_graphs_vec(fsms2_dir)
    fsms3 = load_graphs_vec(fsms3_dir)


    anim = @animate for i ∈ 1:n_gen
        println(i, " ", fsms1[i].num_nodes, " ", fsms2[i].num_nodes )
        start = max(1, i - 50)
        start = 1
        p = plot()
        for (li, color) in zip((l1, l2, l3), colors)
            if i <= size(li, 1)
                p = plot!(p, li[start:i, 1], li[start:i, 2], color=color, lw=2, legend=false, alpha=0.5)
            end
        end
        plot(
            p, 
            plot_colored_graph(fsms1[i], plot_title=fsms1_title),
            plot_colored_graph(fsms2[i], plot_title=fsms2_title),
            plot_colored_graph(fsms3[i], plot_title=fsms3_title),
            plot_title="ADDRESSA-$eco-$trial-$prune: Generation $i", 
            dpi=dpi, 
            layout = l,
            size=(1200, 900)
        )
    end
    
    fname = "addressa-$eco-$trial-$prune.mp4"
    # Save the animation
    gif(anim, fname, fps = 30)
end
# function do_anim_all(;file="data/new_addressa/grow_emb.csv", cutoffs=[1000, 2000, 3000, 4000, 5000], 
#         xlim=(-5, 8), ylim=(5, 18), fname="addressa-new.mp4", dpi=150)
#     # Load the data
#     X = readdlm(file, ',')
#     
#     # Generate a list of data segments based on the cutoffs
#     data_segments = [X[(i == 1 ? 1 : cutoffs[i-1]+1):cutoffs[i], :] for i in 1:length(cutoffs)]
#     l1, l2, l3, l4, l5 = data_segments
# 
#     # Create a plot
#     #plt = plot(xlim=xlim, ylim=ylim, size=(700, 500))
#     colors = [:red, :orange, :blue, :green, :purple]
#     fsms = load_graphs_vec("data/growlink1/")
# 
# 
#     anim = @animate for i ∈ 1:1000
#         println(i)
#             p = plot()
#             for (li, color) in zip((l1, l2, l3, l4, l5), colors)
#                 if i <= size(li, 1)
#                     p = plot!(p, li[1:i, 1], li[1:i, 2], color=color, lw=2, legend=false)
#                 end
#             end
#             plot(p, plot_colored_graph(fsms[i], plot_title="FSM1"), size=(1200, 900), plot_title="ADDRESSA: Epoch $i", dpi=dpi)
#     end
#     
#     # Save the animation
#     gif(anim, fname, fps = 30)
# end