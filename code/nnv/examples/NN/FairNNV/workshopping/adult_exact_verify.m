%% Exact Fairness Verification of Adult Classification Model (NN)
% Comparison for the models used in Fairify

% Suppress warnings
warning('off', 'nnet_cnn_onnx:onnx:WarnAPIDeprecation');
warning('off', 'nnet_cnn_onnx:onnx:FillingInClassNames');

%% Load data into NNV
warning('on', 'verbose')

%% Setup
clear; clc;
modelDir = './adult_onnx';  % Directory containing ONNX models
onnxFiles = dir(fullfile(modelDir, '*.onnx'));  % List all .onnx files
onnxFiles = onnxFiles(1); % simplify for debugging

load("./data/adult_data.mat", 'X', 'y');  % Load data once

%% Loop through each model
for k = 1:length(onnxFiles)
    onnx_model_path = fullfile(onnxFiles(k).folder, onnxFiles(k).name);

    % Load the ONNX file as DAGNetwork
    netONNX = importONNXNetwork(onnx_model_path, 'OutputLayerType', 'classification', 'InputDataFormats', {'BC'});

    % Convert the DAGNetwork to NNV format
    net = matlab2nnv(netONNX);
     
    % Jimmy Rigged Fix: manually edit ouput size
    net.OutputSize = 2;
    
    X_test_loaded = permute(X, [2, 1]);
    y_test_loaded = y+1;  % update labels
    
    % Normalize features in X_test_loaded
    min_values = min(X_test_loaded, [], 2);
    max_values = max(X_test_loaded, [], 2);
    
    % Ensure no division by zero for constant features
    variableFeatures = max_values - min_values > 0;
    min_values(~variableFeatures) = 0; % Avoids changing constant features
    max_values(~variableFeatures) = 1; % Avoids division by zero 

    % Normalizing X_test_loaded
    X_test_loaded = (X_test_loaded - min_values) ./ (max_values - min_values);

    % Count total observations
    total_obs = size(X_test_loaded, 2);
    % disp(['There are total ', num2str(total_obs), ' observations']);

    % Number of observations we want to test
    numObs = 50;
    
    %% Verification
    
    % To save results (robustness and time)
    results = zeros(numObs,2);
    
    % First, we define the reachability options
    reachOptions = struct; % initialize
    reachOptions.reachMethod = 'exact-star';
    
    nR = 50; % ---> just chosen arbitrarily
    
    % ADJUST epsilons value here
    % epsilon = [0.001,0.01];
    epsilon = 0.01;
    
    % Set up results
    nE = 3;
    res = zeros(numObs,nE); % robust result
    time = zeros(numObs,nE); % computation time
    met = repmat("exact", [numObs, nE]); % method used to compute result
 
    % Randomly select observations
    rng(500); % Set a seed for reproducibility
    rand_indices = randsample(total_obs, numObs);
    
    for e=1:length(epsilon)
        % Reset the timeout flag
        assignin('base', 'timeoutOccurred', false);

        % Create and configure the timer
        verificationTimer = timer;
        verificationTimer.StartDelay = 600;  % Set timer for 10 minutes
        verificationTimer.TimerFcn = @(myTimerObj, thisEvent) ...
        assignin('base', 'timeoutOccurred', true);
        start(verificationTimer);  % Start the timer

   
        for i=1:numObs
            idx = rand_indices(i);
            IS = perturbationIF(X_test_loaded(:, idx), epsilon(e), min_values, max_values);
            
            t = tic;  % Start timing the verification for each sample
            
            % temp = net.verify_robustness(IS, reachOptions, unsafeRegion);
            outputSet = net.reach(IS,reachOptions); % Generate output set
            S = imagestar_to_star(outputSet);

            unsafeRegion = net.robustness_set(y_test_loaded(idx), 'min');

            % Verify fairness
            temp = verify_specification(S, unsafeRegion);

            if reachOptions.reachMethod == "exact-star" && temp == 2
                temp = 0;
            end

            met(i,e) = 'exact';
            res(i,e) = temp; % robust result    
            time(i,e) = toc(t); % store computation time

            reachSet = imagestar_to_star(net.reachSet{end});

            if ~(temp == 1)
                counterExs = getCounterRegion(S,unsafeRegion,reachSet);
            end
    
            % Check for timeout flag
            if evalin('base', 'timeoutOccurred')
                disp(['Timeout reached for epsilon = ', num2str(epsilon(e)), ': stopping verification for this epsilon.']);
                res(i+1:end,e) = 2; % Mark remaining as unknown
                break; % Exit the inner loop after timeout
            end
        end

        % disp(counterExs)

        % Summary results, stopping, and deleting the timer should be outside the inner loop
        stop(verificationTimer);
        delete(verificationTimer);
    
        % Get summary results
        N = numObs;
        rob = sum(res(:,e)==1);
        not_rob = sum(res(:,e) == 0);
        unk = sum(res(:,e) == 2);
        totalTime = sum(time(:,e));
        avgTime = totalTime/N;
        
        % Print results to screen
        fprintf('Model: %s\n', onnxFiles(k).name);
        disp("======= FAIRNESS RESULTS e: "+string(epsilon(e))+" ==========")
        disp(" ");
        disp("Number of fair samples = "+string(rob)+ ", equivalent to " + string(100*rob/N) + "% of the samples.");
        disp("Number of non-fair samples = " +string(not_rob)+ ", equivalent to " + string(100*not_rob/N) + "% of the samples.")
        disp("Number of unknown samples = "+string(unk)+ ", equivalent to " + string(100*unk/N) + "% of the samples.");
        disp(" ");
        disp("It took a total of "+string(totalTime) + " seconds to compute the verification results, an average of "+string(avgTime)+" seconds per sample");
    end
end


% Apply perturbation (individual fairness) to sample
function IS = perturbationIF(x, epsilon, min_values, max_values)
    % Applies perturbations on selected features of input sample x
    % Return an ImageStar (IS) and random images from initial set
    SampleSize = size(x);

    disturbance = zeros(SampleSize, "like", x);
    sensitive_rows = [9]; 
    nonsensitive_rows = [1,10,11,12];
    
    % Flip the sensitive attribute
    if x(sensitive_rows) == 1
        x(sensitive_rows) = 0;
    else
        x(sensitive_rows) = 1;
    end
   
    % Apply epsilon perturbation to non-sensitive numerical features
    for i = 1:length(nonsensitive_rows)
        if nonsensitive_rows(i) <= size(x, 1)
            disturbance(nonsensitive_rows(i), :) = epsilon;
        else
            error('The input data does not have enough rows.');
        end
    end

    % Calculate disturbed lower and upper bounds considering min and max values
    lb = max(x - disturbance, min_values);
    ub = min(x + disturbance, max_values);
    IS = ImageStar(single(lb), single(ub)); % default: single (assume onnx input models)

end

% Function to change ImageStar set into Star set
function S = imagestar_to_star(set)
    % Process set
    if ~isa(set, "Star")
        nr = length(set);
        S = Star;
        for s=1:nr
            S = set(s).toStar;
        end
    else
        S = outputSet;
    end
end