%% Robustness verification of a NN (L infinity adversarial attack)


%% Load data into NNV

% Load network 
mnist_model = load('mnist_model_fc.mat');

% Create NNV model
net = matlab2nnv(mnist_model.net);

% Load data (no download necessary)
digitDatasetPath = fullfile(matlabroot,'toolbox','nnet','nndemos', ...
    'nndatasets','DigitDataset');
% Images
imds = imageDatastore(digitDatasetPath, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

N = length(imds.Labels); % number of images in dataset
numClasses = net.OutputSize; % # of classes in dataset

% Adversarial attack (L_inf attack)
% One way to define it is using original image +- disturbance (L_inf epsilon)
ones_ = ones([28 28]); % size of image
epsilon = 1; % pixel values (images are not normalized, they get normalized in the ImageInputLayer)

%% Main computation

% to save results (robustness and time)
results = zeros(N,2);
reachOptions = struct;
reachOptions.reachMethod = 'approx-star';

% Iterate trhough all images
for i=1:N

    % Load image in dataset
    [img, fileInfo] = readimage(imds,i);
    target = double(fileInfo.Label); % label = 0 (index 1 for our network)
    img = double(img); % convert to double

    % Adversarial attack
    disturbance = epsilon * ones_;
    % Ensure the values are within the valid range for pixels ([0 255])
    lb_min = zeros(size(img)); % minimum allowed values for lower bound is 0
    ub_max = 255*ones(size(img)); % maximum allowed values for upper bound is 255
    lb_clip = max((img-disturbance),lb_min);
    ub_clip = min((img+disturbance), ub_max);
    IS = ImageStar(lb_clip, ub_clip); % this is the input set we will use
    
    % Let's evaluate the image and the lower and upper bounds to ensure these
    % are correctly classified

    if ~mod(i,50)
        disp("Verifying image "+string(i)+" out of "+string(N)+" in the dataset...");
    end

    % Begin tracking time after input set is created
    t = tic;

    % Evaluate input image
    Y_outputs = net.evaluate(img); 
    [~, yPred] = max(Y_outputs);
    
    % Evaluate lower and upper bounds
    LB_outputs = net.evaluate(lb_clip);
    [~, LB_Pred] = max(LB_outputs); 
    UB_outputs = net.evaluate(ub_clip);
    [~, UB_Pred] = max(UB_outputs);

    % Check if outputs are violating robustness property
    if any([yPred, LB_Pred, UB_Pred] ~= target)
        results(i,1) = 0;
        results(i,2) = toc(t);
        continue;
    end
    
    % Now, we can do the verification process of this image w/ L_inf attack
    
    % The easiest way to do it is using the verify_robustness function
    % Try first with faster approx method, if not robust, do exact reach

    % Verification
    results(i,1) = net.verify_robustness(IS, reachOptions, target);
    % if results(i,1) == 2 % uncomment to further refine results
    %     reachOpt2 = struct;
    %     reachOpt2.reachMethod = 'exact-star';
    %     reachOpt2.numCores = feature('numcores');
    %     net.verify_robustness(IS, reachOpt2, target);
    % end
    results(i,2) = toc(t);

end

% Get summary results
rob = sum(results(:,1) == 1);
not_rob = sum(results(:,1) == 0);
unk = sum(results(:,1) == 2);
totalTime = sum(results(:,2));
avgTime = totalTime/N;

% Print results to screen
disp("======= ROBUSTNESS RESULTS ==========")
disp(" ");
disp("Number of robust images = "+string(rob)+ ", equivalent to " + string(100*rob/N) + "% of the dataset.");
disp("Number of not robust images = " +string(not_rob)+ ", equivalent to " + string(100*not_rob/N) + "% of the dataset.")
disp("Number of unknown images = "+string(unk)+ ", equivalent to " + string(100*unk/N) + "% of the dataset.");
disp(" ");
disp("It took a total of "+string(totalTime) + " seconds to compute the verification results, an average of "+string(avgTime)+" seconds per image");
