import matplotlib.pyplot as plt
import networkx as nx

# Create a directed graph
G = nx.DiGraph()

# Add edges with labels as edge data
G.add_edge("A-0", "A-P", label='1-P')
G.add_edge("A-0", "B-P", label='0')
G.add_edge("B-0", "B-P", label='P')
G.add_edge("B-0", "C-P", label='01')
G.add_edge("C-1", "B-P", label='1')
G.add_edge("C-1", "C-P", label='0-P')

# Manually set node positions
pos = {"A-0": [1, 3],
       "B-0": [2, 3],
       "C-1": [3, 3],
       "A-P": [1, 1],
       "B-P": [2, 1],
       "C-P": [3, 1]}

# Set node size
node_size = 1200

# Set node and edge colors
node_color = "lightblue"
edge_color = "gray"

# Create figure and axis
fig, ax = plt.subplots(figsize=(8, 6))

# Invert y-axis
ax.invert_yaxis()

# Draw nodes
nx.draw_networkx_nodes(G, pos, ax=ax, node_color=node_color, node_size=node_size)

# Draw node labels
nx.draw_networkx_labels(G, pos, ax=ax, font_size=12)

# Draw edges
nx.draw_networkx_edges(G, pos, ax=ax, edge_color=edge_color)

# Draw edge labels
edge_labels = nx.get_edge_attributes(G, 'label')
nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, ax=ax, font_size=10)

# Remove axis ticks
ax.set_xticks([])
ax.set_yticks([])

# Set axis limits
ax.set_xlim([0.5, 3.5])
ax.set_ylim([0.5, 3.5])

# Set plot title
plt.title("Graph", fontsize=16)

# Adjust spacing
plt.tight_layout()

# Show the plot
plt.show()
