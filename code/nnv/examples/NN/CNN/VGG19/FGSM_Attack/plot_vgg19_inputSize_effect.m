fprintf('\n\n=============================LOAD VGG19 ======================\n');

% Load the trained model 
net = vgg19();

fprintf('\n\n======================== PARSING VGG19 =======================\n');
nnvNet = matlab2nnv(net);


fprintf('\n\n=========CONSTRUCT INPUT SET (AN IMAGESTAR SET) =============\n');
load image_data.mat;
V(:,:,:,1) = double(ori_image);
V(:,:,:,2) = double(dif_image);

l = 0.5; % test at l = 50%
delta = [0.0000001 0.00000012 0.00000015 0.00000017 0.00000018, 0.0000002];
n = length(delta);
pred_ub = zeros(n, 1);
pred_lb = zeros(n, 1);

num_ImageStars = zeros(n, 1);
reachOptions = struct;
reachOptions.reachMethod = 'exact-star';

% Begin reachability analysis
for i=1:n
    pred_lb(i) = l;
    pred_ub(i) = l + delta(i);
    
    C = [1;-1];   % pred_lb % <= alpha <= pred_ub percentage of FGSM attack
    d = [pred_ub(i); -pred_lb(i)];
    IS = ImageStar(double(V), C, d, pred_lb(i), pred_ub(i));

    fprintf('\n\n======= COMPUTE NUMBER OF IMAGESTARS IN EXACT ANALYSIS ======\n');
    nnvNet.reach(IS, reachOptions);
    num_ImageStars(i) = length(nnvNet.reachSet{end});    
end


figure;
plot(num_ImageStars, delta, '--x');
ax = gca;
ax.FontSize = 13; 
xlabel('Number of ImageStars','FontSize',13);
ylabel('$\delta_{max}$', 'FontSize', 13, 'Interpreter', 'Latex');


