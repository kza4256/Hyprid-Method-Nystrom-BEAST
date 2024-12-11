clear all; close all; clc;

%% Load data (Replace with your data loading code)
    AW20 = load('FM_RAT_PT20_smooth.mat');
    ChangePoints = load('BEAST_NYST_150CPs.mat');
    
    Y = AW20.FM_RAT_PT20_smooth;
    n = 1 * 3000; % Number of data points
    m = 4;
    y = Y(1, 1:n)';
    time = 1/3000:1/3000:1;
    N = length(y);

%% Beast matrix: % x = fun_interp;
    all_time_cps_concatenated = ChangePoints.all_time_cps_concatenated;
    all_values_cps_concatenated = ChangePoints.all_values_cps_concatenated;

%% Initialize number of landmarks and other variables
    total_landmarks = 150; % You specify 
    execution_times = [];
    relative_errors = [];
    num_iterations = total_landmarks;

%% Main Loop: Alternate between CP and random landmarks
    for iter = 0:total_landmarks
        tic;
        
        % Number of CP landmarks to select
        num_cp_landmarks = min(iter, length(all_time_cps_concatenated));
        selected_indices = round(linspace(1, length(all_time_cps_concatenated), num_cp_landmarks));
        cp_landmark_times = all_time_cps_concatenated(selected_indices);
        cp_landmark_values = all_values_cps_concatenated(selected_indices);
        
        % Random landmarks - Ensure to include endpoints
        num_random_landmarks = total_landmarks - num_cp_landmarks;

        % Random-only case: Only pick random points, including endpoints
        random_indices = randperm(length(time), num_random_landmarks); % Avoid first and last point
        random_landmark_times = [time(1), time(random_indices), time(end)];
        random_landmark_values = [y(1); y(random_indices); y(end)];


         % Sort random landmarks by time for correct line connections
        [random_landmark_times, sort_rnd_idx] = sort(random_landmark_times);
        random_landmark_values = random_landmark_values(sort_rnd_idx);

        % Remove endpoints from random landmarks in combined plot
        if iter > 0 % Ensuring there are random landmarks to select
            random_landmark_times_combined = random_landmark_times(2:end-1); % Exclude endpoints
            random_landmark_values_combined = random_landmark_values(2:end-1); % Exclude endpoints
        else
            random_landmark_times_combined = random_landmark_times; % No random landmarks case
            random_landmark_values_combined = random_landmark_values;
        end
        
        combined_landmark_times = [cp_landmark_times, random_landmark_times_combined];
        combined_landmark_values = [cp_landmark_values, random_landmark_values_combined'];
        
        % Ensure to include the endpoints only once for the full time series range
        combined_landmark_times = [time(1), combined_landmark_times, time(end)];
        combined_landmark_values = [y(1), combined_landmark_values, y(end)];
        
        % Sort combined landmarks
        if ~isempty(combined_landmark_times)
            [combined_landmark_times, sort_idx] = sort(combined_landmark_times);
            combined_landmark_values = combined_landmark_values(sort_idx);
        end
           
        % Reconstruct with CP landmarks only
        [alpha0_cp, subset_cp, Y2_cp] = km_krr_nystrom(time, y, 'gauss', 1, num_cp_landmarks, cp_landmark_times);
        
        % Reconstruct with random landmarks only
        [alpha0_random, subset_random, Y2_random] = km_krr_nystrom(time, y, 'gauss', 1, num_random_landmarks, random_landmark_times);
        
        % Reconstruct with combined landmarks
        [alpha0_combined, subset_combined, Y2_combined] = km_krr_nystrom(time, y, 'gauss', 1, total_landmarks, combined_landmark_times);
        
        % Calculate execution times and relative errors
        execution_time = toc;
        execution_times = [execution_times, execution_time];
        
        reconstruction_error = norm(Y2_combined(subset_combined) - combined_landmark_values, 'fro') / total_landmarks;
        relative_errors = [relative_errors, reconstruction_error];
        
        % Side-by-side plot of reconstructions
        figure;
        
        % Plot CP-only reconstruction
        subplot(1,3,1);
        scatter(time, y, 'x', 'MarkerEdgeColor', 'k', 'DisplayName', 'True Signal'); alpha(0.2); hold on;
        scatter(cp_landmark_times, cp_landmark_values, 50, 'g', 'filled', 'DisplayName', 'CP Landmarks');
        plot(cp_landmark_times, cp_landmark_values, '-b', 'LineWidth', 1.5, 'DisplayName', 'CP-Only Reconstruction');
        title(sprintf('CP-Only Reconstruction (Iter: %d)', iter));
        xlabel('Time'); ylabel('Signal Value'); legend;
        
        % Plot Random-only reconstruction
        subplot(1,3,2);
        scatter(time, y, 'x', 'MarkerEdgeColor', 'k', 'DisplayName', 'True Signal'); alpha(0.2); hold on;
        scatter(random_landmark_times, random_landmark_values, 50, 'r', 'filled', 'DisplayName', 'Random Landmarks');
        plot(random_landmark_times, random_landmark_values, '-b', 'LineWidth', 1.5, 'DisplayName', 'Random-Only Reconstruction');
        title(sprintf('Random-Only Reconstruction (Iter: %d)', iter));
        xlabel('Time'); ylabel('Signal Value'); legend;

        % Plot combined reconstruction
        subplot(1,3,3);
        scatter(time, y, 'x', 'MarkerEdgeColor', 'k', 'DisplayName', 'True Signal'); alpha(0.2); hold on;
        scatter(cp_landmark_times, cp_landmark_values, 50, 'g', 'filled', 'DisplayName', 'CP Landmarks');
        scatter(random_landmark_times, random_landmark_values, 50, 'r', 'filled', 'DisplayName', 'Random Landmarks');
        plot(combined_landmark_times, combined_landmark_values, '-b', 'LineWidth', 1.5, 'DisplayName', 'Combined Reconstruction');
        title(sprintf('Combined Reconstruction (Iter: %d)', iter));
        xlabel('Time'); ylabel('Signal Value'); legend; hold off;
    end

%% Plot relative error vs. execution time with consistent coloring
    figure;
    cmap = colormap(jet);
    normalized_errors = (relative_errors - min(relative_errors)) / (max(relative_errors) - min(relative_errors));
    color_indices = round(normalized_errors * (size(cmap, 1) - 1)) + 1;
    
    % Plot scatter points
    scatter(execution_times, relative_errors, 50, cmap(color_indices, :), 'filled');
    xlabel('Execution Time (seconds)');
    ylabel('Relative Reconstruction Error');
    title('Relative Error vs. Execution Time');
    
    % Color bar to reflect relative error
    cb = colorbar;
    caxis([min(relative_errors), max(relative_errors)]);
    
    % Annotate the color bar
    annotation('textbox', [0.85, 0.2, 0.1, 0.05], 'String', 'More CPs', 'EdgeColor', 'none', 'FontSize', 10, 'Color', 'black');
    annotation('textbox', [0.85, 0.8, 0.1, 0.05], 'String', 'More Random', 'EdgeColor', 'none', 'FontSize', 10, 'Color', 'black');
    
    % Set axes position for a clearer plot layout
    set(gca, 'Position', [0.1, 0.1, 0.75, 0.8]);
    
    % Annotate each point with the number of CPs and random landmarks
    for iter = 0:total_landmarks
        num_cp_landmarks = min(iter, length(all_time_cps_concatenated));
        num_random_landmarks = total_landmarks - num_cp_landmarks;    
    end
