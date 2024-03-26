import json
import plotly.graph_objects as go
import os
import sys

def load_metadata(metadata_file):
    """
    Load metadata from a text file.
    """
    metadata = {}
    current_category = None

    with open(metadata_file, 'r') as f:
        for line in f:
            line = line.strip()
            print("Processing line:", line)  # Debug print to check each line
            if line.startswith('#'):
                current_category = line[1:].strip()
                metadata[current_category] = {}
            elif line:
                key, value = line.split('=')
                metadata[current_category][key.strip()] = value.strip()

    print("Parsed Metadata Keys:", metadata.keys())  # Debug print parsed metadata keys
    return metadata

def load_stats(stats_file):
    """
    Load statistics from a JSON file.
    """
    with open(stats_file, 'r') as f:
        stats_data = json.load(f)

    return stats_data

def sort_processes(processes, metadata):
    """
    Sort processes based on specified criteria.
    """
    sorted_processes = sorted(processes, key=lambda x: (
        int(metadata[x].get('OEM_CARS_INITIAL', 0)),
        int(metadata[x].get('SUPPLIER_PARTS_INITIAL', 0)),
        int(metadata[x].get('OEM_PLANTS', 0)),
        int(metadata[x].get('SUPPLIER_PLANTS', 0)),
        int(metadata[x].get('SUPPLIER_FLEET_MANAGERS', 0)),
        int(metadata[x].get('ADDITIONAL_CONTRACT_DEFINITIONS_OEM', 0)),
        int(metadata[x].get('ADDITIONAL_CONTRACT_DEFINITIONS_SUPPLIER', 0)),
    ))
    print("Sorted Processes:", sorted_processes)
    for process in sorted_processes:
        print(f"Metadata for {process}: {metadata[process]}")
    return sorted_processes

def plot_data(processes, stats_data, metadata, output_file):
    """
    Plot median response time data for each process as bar charts and save to HTML.
    """
    fig = go.Figure()

    for process in processes:
        stats = stats_data.get(process, {})
        median_res_time = stats.get('medianResTime')  # Check if 'medianResTime' exists in stats
        if median_res_time is not None:
            process_info = metadata[process]
            process_label = f"{process}\nCars: {process_info['OEM_CARS_INITIAL']}, Parts: {process_info['SUPPLIER_PARTS_INITIAL']}, OEM Plants: {process_info['OEM_PLANTS']}, Supplier Plants: {process_info['SUPPLIER_PLANTS']}, Fleet Managers: {process_info['SUPPLIER_FLEET_MANAGERS']}"
            print(f"Adding trace for {process} with medianResTime {median_res_time}")
            fig.add_trace(go.Bar(x=[process_label], y=[median_res_time], name=process_label))

    fig.update_layout(title='Median Response Time for JMeter Calls',
                      xaxis_title='Evaluation Scenarios',
                      yaxis_title='Median Response Time',
                      barmode='group')  # Change to 'group' for multiple bars per scenario

    print("Final Figure:", fig)  # Print the figure object for debugging
    fig.write_html(output_file)

def process_folders(root_folder, output_file):
    """
    Process folders inside the root folder to get metadata and statistics files.
    """
    processes = []
    stats_data = {}
    metadata = {}

    for folder in os.listdir(root_folder):
        folder_path = os.path.join(root_folder, folder)
        if os.path.isdir(folder_path):
            metadata_file = os.path.join(folder_path, 'metadata.txt')
            dashboard_folder = os.path.join(folder_path, 'dashboard')
            stats_file = os.path.join(dashboard_folder, 'statistics.json')

            if os.path.exists(metadata_file) and os.path.exists(stats_file):
                metadata[folder] = load_metadata(metadata_file)
                stats_data.update(load_stats(stats_file))
                processes.append(folder)

    sorted_processes = sort_processes(processes, metadata)
    plot_data(sorted_processes, stats_data, metadata, output_file)

def main(root_folder=None, output_file=None):
    """
    Main function to aggregate and plot data from folders.
    """
    if root_folder is None:
        root_folder = '.'  # Set current folder if no root_folder provided

    if output_file is None:
        output_file = 'output.html'  # Set default output file name if not provided

    process_folders(root_folder, output_file)

if __name__ == "__main__":
    root_folder = sys.argv[1] if len(sys.argv) > 1 else None
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    main(root_folder, output_file)
