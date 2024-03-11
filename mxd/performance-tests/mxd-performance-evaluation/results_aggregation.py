import json
import matplotlib.pyplot as plt
import numpy as np
import mplcursors
import os
import random
import sys

def extract_values(file_path):
    """
    Extract values from a metadata file.
    """
    values = {}
    with open(file_path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            if 'OEM_PLANTS' in line:
                values['OEM_PLANTS'] = int(line.split('=')[1].strip())
            elif 'OEM_CARS_INITIAL' in line:
                values['OEM_CARS_INITIAL'] = int(line.split('=')[1].strip())
            elif 'PARTS_PER_CAR' in line:
                values['PARTS_PER_CAR'] = int(line.split('=')[1].strip())
            elif 'CARS_PRODUCED_PER_INTERVALL' in line:
                values['CARS_PRODUCED_PER_INTERVAL'] = int(line.split('=')[1].strip())
    return values


def load_stats(file_path):
    """
    Load statistics from a JSON file.
    """
    with open(file_path, 'r') as f:
        return json.load(f)


def plot_data(stats, labels, value, meta_values_list):
    """
    Plot statistics data.
    """
    plt.figure(figsize=(15, 4))
    plt.title('Aggregation of Performance Test Results: {}'.format(value))
    plt.xlabel('OEM_PLANTS')
    plt.ylabel(value)

    for i, (s, l, meta) in enumerate(zip(stats, labels, meta_values_list)):
        plt.plot(s[0], s[1], 'o', label=l)
        plt.text(s[0], s[1], l)
        plt.annotate('Plants: {}, Cars: {}, Parts/Car: {}, Cars/Interval: {}'.format(
            meta['OEM_PLANTS'],
            meta['OEM_CARS_INITIAL'],
            meta['PARTS_PER_CAR'],
            meta['CARS_PRODUCED_PER_INTERVAL']),
            (s[0], s[1]))

    plt.legend()
    plt.show()


def main(root_folder=None):
    """
    Main function to aggregate and plot data.
    """
    if root_folder is None:
        root_folder = '.'  # Set current folder if no root_folder provided

    value_names = ['meanResTime', 'sampleCount']
    processes = ['Get Transfer State', 'Initiate Transfer']

    directories = [os.path.join(root_folder, o) for o in os.listdir(root_folder) if os.path.isdir(os.path.join(root_folder, o))]
    stats = []
    labels = []
    meta_values_list = []

    for directory in directories:
        metadata_path = os.path.join(directory, 'metadata.txt')
        statistics_path = os.path.join(directory, 'dashboard/statistics.json')

        if os.path.exists(metadata_path) and os.path.exists(statistics_path):
            meta_values = extract_values(metadata_path)
            stats_data = load_stats(statistics_path)

            for action_to_consider in processes:
                for value in value_names:
                    if action_to_consider in stats_data:
                        action = stats_data[action_to_consider]
                        if value in action:
                            stats.append((meta_values['OEM_PLANTS'], action[value]))
                            labels.append('Plants: {}, {}: {:.2f}'.format(meta_values['OEM_PLANTS'], value,
                                                                          round(action[value], 2)))
                            meta_values_list.append(meta_values)

    plot_data(stats, labels, value, meta_values_list)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1])
    else:
        main()
