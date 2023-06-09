import os
import csv
import pandas as pd
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

#xml = graphml_to_networkx('test.xml')
#plot_graph_with_edge_labels(xml)


def combine_csv_files(input_directory, output_file):
    # Get a list of all CSV files in the directory
    csv_files = [file for file in os.listdir(input_directory) if file.endswith(".csv")]

    # Initialize an empty list to store the combined data
    combined_data = []

    # Iterate over each CSV file
    for file in csv_files:
        with open(os.path.join(input_directory, file), 'r') as csvfile:
            csvreader = csv.reader(csvfile)
            next(csvreader)  # Skip header if present

            # Append data rows to the combined list
            combined_data.extend(csvreader)

    # Write the combined data to a new CSV file
    with open(output_file, 'w', newline='') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerow(["left", "right", "dist"])  # Write header
        csvwriter.writerows(combined_data)

# Usage example
# combine_csv_files("/path/to/input/directory", "/path/to/output/file.csv")

def analyze_data(csv_file = "fsm_dist.csv"):
    # Read the CSV file into a pandas DataFrame
    df = pd.read_csv(csv_file)

    # Compute summary statistics
    min_dist = df['dist'].min()
    max_dist = df['dist'].max()
    mean_dist = df['dist'].mean()
    median_dist = df['dist'].median()
    std_dist = df['dist'].std()

    # Print the summary statistics
    print("Summary Statistics:")
    print("Min Distance:", min_dist)
    print("Max Distance:", max_dist)
    print("Mean Distance:", mean_dist)
    print("Median Distance:", median_dist)
    print("Standard Deviation:", std_dist)

    # Plot a histogram of the "dist" column
    plt.hist(df['dist'], bins=10)
    plt.xlabel('Distance')
    plt.ylabel('Frequency')
    plt.title('Histogram of Distance')
    plt.show()

# Usage example