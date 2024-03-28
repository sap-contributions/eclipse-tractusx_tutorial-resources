import json
import plotly.graph_objects as go
import os
import sys
import numpy as np
from sklearn.linear_model import LinearRegression
import argparse

OEM_CARS_INITIAL = 'OEM_CARS_INITIAL'
SUPPLIER_PARTS_INITIAL = 'SUPPLIER_PARTS_INITIAL'
OEM_PLANTS = 'OEM_PLANTS'
SUPPLIER_PLANTS = 'SUPPLIER_PLANTS'
SUPPLIER_FLEET_MANAGERS = 'SUPPLIER_FLEET_MANAGERS'
ADDITIONAL_CONTRACT_DEFINITIONS_OEM = 'ADDITIONAL_CONTRACT_DEFINITIONS_OEM'
ADDITIONAL_CONTRACT_DEFINITIONS_SUPPLIER = 'ADDITIONAL_CONTRACT_DEFINITIONS_SUPPLIER'
DEFAULT_OUTPUT_FILE = 'output.html'
USAGE_MESSAGE = 'Usage: python3 results_aggregation.py <directory> <html_file> --regression <operation_name>'


def load_metadata(metadata_file):
    """
    Load metadata from a text file.
    """
    metadata = {}

    with open(metadata_file, 'r') as f:
        for line in f:
            line = line.strip()
            if "=" in line:
                key, value = line.split('=')
                metadata[key.strip()] = value.strip()
    return metadata


def load_stats(stat_file):
    """
    Load statistics from a JSON file.
    """
    with open(stat_file, 'r') as file:
        data = json.load(file)

    processes_data = {}

    for process_name, process_data in data.items():
        median_res_time = process_data['medianResTime']
        processes_data[process_name] = median_res_time

    return processes_data


def sort_processes(processes, metadata):
    """
    Sort processes based on specified criteria.
    """
    sorted_processes = sorted(processes, key=lambda x: (
        int(metadata[x].get(OEM_CARS_INITIAL)),
        int(metadata[x].get(SUPPLIER_PARTS_INITIAL)),
        int(metadata[x].get(OEM_PLANTS)),
        int(metadata[x].get(SUPPLIER_PLANTS)),
        int(metadata[x].get(SUPPLIER_FLEET_MANAGERS)),
        int(metadata[x].get(ADDITIONAL_CONTRACT_DEFINITIONS_OEM)),
        int(metadata[x].get(ADDITIONAL_CONTRACT_DEFINITIONS_SUPPLIER)),
    ))
    return sorted_processes


def erase_file_contents(filename):
    if os.path.exists(filename):
        with open(filename, 'w') as file:
            pass


def plot_process_data(scenarios, stats_data, output_file):
    figures = []
    all_calls = stats_data[scenarios[0]].keys()

    for c in all_calls:
        x_axis_data = []
        y_axis_data = []
        for s in scenarios:
            mapping = stats_data[s]
            if not mapping.get(c) is None:
                response_time = stats_data[s][c]
                y_axis_data.append(response_time)
                x_axis_data.append(s)
        trace = go.Bar(
            x=x_axis_data,
            y=y_axis_data
        )

        layout = go.Layout(
            title=c,
            xaxis=dict(title=c),
            yaxis=dict(title='Median Response Time(ms)')
        )
        fig = go.Figure(data=[trace], layout=layout)
        figures.append(fig)

    erase_file_contents(output_file)

    with open(output_file, 'a') as f:
        for fig in figures:
            f.write(fig.to_html(full_html=False, include_plotlyjs='cdn'))
            f.write('<div style="height: 50px;"></div>')


def analyze_response_time(output_file, metadata, stats_data, scenarios, operation_name):
    contract_def_list = []
    response_time_list = []

    for s in scenarios:
        contract_def = metadata[s][ADDITIONAL_CONTRACT_DEFINITIONS_OEM]
        response_time = stats_data[s].get(operation_name)
        contract_def_list.append(float(contract_def))
        response_time_list.append(float(response_time))

    contract_def_array = np.array(contract_def_list)
    response_time_array = np.array(response_time_list)

    x = contract_def_array.reshape(-1, 1)
    y = response_time_array

    model = LinearRegression()
    model.fit(x, y)

    html_content = f"<p>Analyzing Resp Time(OEM)\n</p>\n"
    html_content += f"<p>Intercept: {model.intercept_}</p>\n"
    html_content += f"<p>Slope (Beta param): {model.coef_[0]}</p>\n"

    x_prediction = np.linspace(min(contract_def_array),
                               max(contract_def_array),
                               100).reshape(-1, 1)
    y_prediction = model.predict(x_prediction)

    scatter_trace = go.Scatter(
        x=contract_def_array,
        y=response_time_array,
        mode='markers',
        marker=dict(color='blue'),
        name='Data Points'
    )

    regression_line_trace = go.Scatter(
        x=x_prediction.flatten(),
        y=y_prediction,
        mode='lines',
        line=dict(color='red'),
        name='Regression Line'
    )

    layout = go.Layout(
        title='Linear Regression',
        xaxis=dict(title='Amount of Contract Definition'),
        yaxis=dict(title='Median Response Time(ms)')
    )

    fig = go.Figure(data=[scatter_trace, regression_line_trace], layout=layout)

    with open(output_file, 'a') as f:
        f.write(html_content)
        f.write(fig.to_html(full_html=False, include_plotlyjs='cdn'))


def process_folders(root_folder, output_file, operation_name):
    """
    Process folders inside the root folder to get metadata and statistics files.
    """
    scenarios = []
    stats_data = {}
    metadata = {}

    for ex_folder in os.listdir(root_folder):
        ex_path = os.path.join(root_folder, ex_folder)
        if os.path.isdir(ex_path):
            ex_contents = os.listdir(ex_path)
            if os.path.isdir(ex_path):
                for item in ex_contents:
                    output_path = os.path.join(ex_path, item)
                    if os.path.isdir(output_path):
                        metadata_file = os.path.join(output_path, 'metadata.txt')
                        dashboard_folder = os.path.join(output_path, 'dashboard')
                        stats_file = os.path.join(dashboard_folder, 'statistics.json')
                        if os.path.exists(metadata_file) and os.path.exists(stats_file):
                            scenario = ex_folder.split('.')[0] if '.' in ex_folder else ex_folder
                            scenarios.append(scenario)
                            metadata[scenario] = load_metadata(metadata_file)
                            stats_data[scenario] = (load_stats(stats_file))

    sorted_scenarios = sort_processes(scenarios, metadata)
    plot_process_data(sorted_scenarios, stats_data, output_file)
    analyze_response_time(output_file, metadata, stats_data, scenarios, operation_name)


def main(root_folder, output_file, operation_name):
    process_folders(root_folder, output_file, operation_name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Test Result Aggregation Script')
    parser.add_argument('arguments',
                        nargs=2,
                        metavar=('directory', 'html_file'),
                        help='Directory and HTML file arguments.')
    parser.add_argument('--regression',
                        type=str,
                        help='operation name for regression analysis')

    try:
        args = parser.parse_args()
    except TypeError as e:
        print("Error: Test directory or output file name is missing")
        print(USAGE_MESSAGE)
        sys.exit(1)

    if not args.regression:
        print("Error: The --regression argument is required.")
        print(USAGE_MESSAGE)
        sys.exit(1)

    directory, html_file = args.arguments
    operation_name = args.regression
    main(directory, html_file, operation_name)
