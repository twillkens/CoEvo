import matplotlib.pyplot as plt
import networkx as nx

def graphml_to_networkx(filepath):
    # Read the graphml file
    graph = nx.read_graphml(filepath)
    
    return graph

# Create a graph and add nodes and edges
def plot_graph_with_edge_labels(G, edge_attr='label'):
    # Set positions for all nodes
    pos = nx.spring_layout(G)

    # Draw nodes
    nx.draw_networkx_nodes(G, pos, node_size=700)

    # Draw edges
    nx.draw_networkx_edges(G, pos)

    # Draw node labels
    nx.draw_networkx_labels(G, pos, font_size=20, font_family="sans-serif")

    # Draw edge labels
    edge_labels = nx.get_edge_attributes(G, edge_attr)
    print(edge_labels)
    nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels)

    plt.axis("off")
    plt.show()

xml = graphml_to_networkx('test.xml')
plot_graph_with_edge_labels(xml)