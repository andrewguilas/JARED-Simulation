clc;
clear;
close all;

% Read the CSV file
data = csvread('Trial1.csv');

% Define the labels for each row
labels = {'ONE_WAY_SAME_SIDE_ENTER', 'ONE_WAY_SAME_SIDE_EXIT', 'TWO_WAY_ENTER', 'TWO_WAY_EXIT', 'ONE_WAY_ENTER', 'ONE_WAY_EXIT'};

% Determine the number of rows and columns
num_rows = size(data, 1);
num_cols = size(data, 2);

% Calculate the bin edges for all histograms
min_val = min(data(:));
max_val = max(data(:));
edges = linspace(min_val, max_val, 20); % Adjust the number of bins as needed

% Create a new figure
figure;

% Iterate over each row and create histograms
for i = 1:num_rows
    % Extract data from the current row
    row_data = data(i, 2:end);
    
    % Create subplot
    subplot(2, 3, i);
    
    % Plot histogram with the same bin edges
    histogram(row_data, edges);
    
    % Add title and labels
    title(labels{i});
    xlabel('Value');
    ylabel('Frequency');
end
