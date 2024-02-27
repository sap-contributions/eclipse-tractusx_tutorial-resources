import json
import matplotlib.pyplot as plt # to install: pip3 install plotly
import numpy as np
import mplcursors  # to install: pip3 install mplcursors
import os
import random

############ Required Input ############
root_folder = './Ergebnisse'
values = ['meanResTime', 'sampleCount']
processes = ['Get Transfer State', 'Initiate Transfer']

######################################################################################
# A function for extracting values from a given file
def extract_values(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    values = {}
    for line in lines:
        if 'OEM_PLANTS' in line:
            values['OEM_PLANTS'] = int(line.split('=')[1].strip())
        elif 'OEM_CARS_INITIAL' in line:
            values['OEM_CARS_INITIAL'] = int(line.split('=')[1].strip())
        elif 'PARTS_PER_CAR' in line:
            values['PARTS_PER_CAR'] = int(line.split('=')[1].strip())
        elif 'CARS_PRODUCED_PER_INTERVALL' in line:
            values['CARS_PRODUCED_PER_INTERVALL'] = int(line.split('=')[1].strip())
    return values

# List comprehension to gather all directories under the specified root_folder
directories = [os.path.join(root_folder, o) for o in os.listdir(root_folder) 
    if os.path.isdir(os.path.join(root_folder,o))]

# Iterates over each action and value from the lists and creates a new figure for each combination
for action_to_consider in processes:
    for value_idx, value in enumerate(values):
        plt.figure(figsize=(15, 4))
        plt.title('Aggregation of Performance Test Results: {} for {}'.format(value, action_to_consider))

        stats = []
        labels = []
        meta_values_list = []

        # Goes through each directory to find the metadata and statistics files
        for idx, directory in enumerate(directories):
            metadata_path = os.path.join(directory, 'metadata.txt')  
            statistics_path = os.path.join(directory, 'dashboard/statistics.json')  
            
            # If both files exist in the directory, it calls the function to extract values from the metadata file
            if os.path.exists(metadata_path) and os.path.exists(statistics_path):
                meta_values = extract_values(metadata_path)

                # Opens the statistics.json file and loads its content
                with open(statistics_path, 'r') as f:
                    stats_data = json.load(f)

                # Appends the statistics for each action and the associated labels for the plot
                action = stats_data[action_to_consider]
                stats.append((meta_values['OEM_PLANTS'], action[value]))
                labels.append('Plants: {}, {}: {:.2f}'.format(meta_values['OEM_PLANTS'], value, round(action[value],2)))
                meta_values_list.append(meta_values)

        # Plots the statistics data as a line plot and a scatter plot
        plt.plot([s[0] for s in stats], [s[1] for s in stats])
        colors = [ (random.random(), random.random(), random.random()) for _ in range(len(stats)) ]
        scatter = plt.scatter([s[0] for s in stats], [s[1] for s in stats], color=colors)

        # Adds labels to each point on the scatter plot (that x-axis matches OEM_PLANTS values)
        for i, text in enumerate(labels):
            plt.text(stats[i][0], stats[i][1], text)

        # Add cursor
        cursor = mplcursors.cursor(scatter, hover=True)
        @cursor.connect("add")
        def on_add(sel):
            i = sel.target.index
            sel.annotation.set_text('Plants: {}, Cars: {}, Parts/Car: {}, Cars/Interval: {}'.format(
                stats[i][0],
                meta_values_list[i]['OEM_CARS_INITIAL'],
                meta_values_list[i]['PARTS_PER_CAR'],
                meta_values_list[i]['CARS_PRODUCED_PER_INTERVALL']))

        plt.xlabel('OEM_PLANTS')
        plt.ylabel(value)
        plt.show()