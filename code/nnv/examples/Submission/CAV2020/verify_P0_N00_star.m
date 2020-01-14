function results = verify_P0_N00_star(N1, N2)

addpath(genpath("../../../engine"));
addpath(genpath("../../../tbxmanager"));
addpath("nnet-mat-files/")
load(['ACASXU_run2a_',num2str(N1),'_',num2str(N2),'_batch_2000.mat']);
% edit property here
P0 = 2;
lb = [60750;3.13;3.13;1190;55];
ub = [60760;3.14;3.14;1200;60];
unsafe_mat = [-1,1,0,0,0;-1,0,1,0,0;-1,0,0,1,0;-1,0,0,0,1];
unsafe_vec = [0;0;0;0];

Layers = [];
n = length(b);
for i=1:n - 1
    bi = cell2mat(b(i));
    Wi = cell2mat(W(i));
    Li = LayerS(Wi, bi, 'poslin');
    Layers = [Layers Li];
end
bn = cell2mat(b(n));
Wn = cell2mat(W(n));
Ln = LayerS(Wn, bn, 'purelin');

Layers = [Layers Ln];
F = FFNNS(Layers);

% normalize input
for i=1:5
    lb(i) = (lb(i) - means_for_scaling(i))/range_for_scaling(i);
    ub(i) = (ub(i) - means_for_scaling(i))/range_for_scaling(i);   
end

I = Star(lb, ub);

c = parcluster('local');
numCores = c.NumWorkers;

[R1, ~] = F.reach(I, 'exact-star', numCores); % exact reach set using polyhdedron

normalized_mat = range_for_scaling(6) * eye(5);
normalized_vec = means_for_scaling(6) * ones(5,1);

t = tic;
n = length(R1);
R1_norm = [];
parfor i=1:n
    R1_norm = [R1_norm  R1(i).affineMap(normalized_mat, normalized_vec)]; % exact normalized reach set
end
check_time = toc(t);

t = tic;
fprintf('\nVerifying exact star reach set...');
unsafe = 0;
n = length(R1);
parfor i=1:n
    S = R1_norm(i).intersectHalfSpace(unsafe_mat, unsafe_vec);
    if ~isempty(S)
        unsafe = unsafe + 1;
    end
end

check_time = check_time + toc(t);

if unsafe>=1
    safe = 0;
else
    safe = 1;
end

results.safe = safe;
results.set_number = length(F.outputSet);
results.total_time = check_time + F.totalReachTime;
save(['../../../../../../logs/logs_nnv_star/P',num2str(P0),'_N',num2str(N1),num2str(N2),'_star.mat'],'results')
