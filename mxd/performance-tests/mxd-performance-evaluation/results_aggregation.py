import json
import plotly.graph_objects as go
import os
import sys

def load_metadata(metadata_file):
    """
    Load metadata from a text file.
    """
    with open(metadata_file, 'r') as f:
        metadata_content = f.read()

    metadata = {}
    current_category = None

    for line in metadata_content.splitlines():
        line = line.strip()
        if line.startswith('#'):
            current_category = line[1:].strip()
            metadata[current_category] = {}
        elif line:
            key, value = line.split('=')
            metadata[current_category][key.strip()] = value.strip()

    return metadata

def load_stats(stats_file):
    """
    Load statistics from a JSON file.
    """
    with open(stats_file, 'r') as f:
        stats_data = json.load(f)

    # Extract 'medianResTime' values for each process
    extracted_data = {}
    for process, stats in stats_data.items():
        median_res_time = stats.get('medianResTime')
        if median_res_time is not None:
            extracted_data[process] = {'medianResTime': median_res_time}

    return extracted_data

def sort_processes(processes):
    """
    Sort processes based on specified criteria.
    """
    sorted_processes = sorted(processes)
    print("Sorted Processes:", sorted_processes)
    return sorted_processes

def plot_data(processes, stats_data, output_file):
    """
    Plot median response time data for each process as bar charts and save to HTML.
    """
    fig = go.Figure()

    for process in processes:
        stats = stats_data.get(process, {})
        median_res_time = stats.get('medianResTime')  # Check if 'medianResTime' exists in stats
        if median_res_time is not None:
            print(f"Adding trace for {process} with medianResTime {median_res_time}")
            fig.add_trace(go.Bar(x=[process], y=[median_res_time], name=process))
        else:
            print(f"No medianResTime found for {process}")

    fig.update_layout(title='Median Response Time for JMeter Calls',
                      xaxis_title='Processes',
                      yaxis_title='Median Response Time')

    print("Final Figure:", fig)  # Print the figure object for debugging
    fig.write_html(output_file)

def process_folders(root_folder, output_file):
    """
    Process folders inside the root folder to get metadata and statistics files.
    """
    processes = []
    stats_data = {}

    for folder in os.listdir(root_folder):
        folder_path = os.path.join(root_folder, folder)
        if os.path.isdir(folder_path):
            metadata_file = os.path.join(folder_path, 'metadata.txt')
            dashboard_folder = os.path.join(folder_path, 'dashboard')
            stats_file = os.path.join(dashboard_folder, 'statistics.json')

            if os.path.exists(metadata_file) and os.path.exists(stats_file):
                metadata = load_metadata(metadata_file)
                stats = load_stats(stats_file)
                process_name = metadata['General Parameters'].get('PROCESS_NAME', 'Unknown')
                processes.append(process_name)
                stats_data[process_name] = stats

    sorted_processes = sort_processes(processes)
    plot_data(sorted_processes, stats_data, output_file)

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
