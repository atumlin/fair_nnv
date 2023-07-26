%% this file generates fig. 3 captioned
% "Percentage Robustness and Runtime plots w.r.t increasing noise"

load SOC_results.mat;
figure;

subplot(1,3,1);
plot(100*[0 perturbations],100*[1, PR_SFSI{3,1},PR_SFSI{3,2},PR_SFSI{3,3},PR_SFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, PR_SFAI{3,1},PR_SFAI{3,2},PR_SFAI{3,3},PR_SFAI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, PR_MFSI{3,1},PR_MFSI{3,2},PR_MFSI{3,3},PR_MFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, PR_MFAI{3,1},PR_MFAI{3,2},PR_MFAI{3,3},PR_MFAI{3,4}]);
xlabel('Pecentage Noise (%) ');
ylabel('Percentage Robustness by Samples (%)')
set(gca, 'FontSize', 22);


subplot(1,3,2);
plot(100*[0 perturbations],100*[1, POR_SFSI{3,1},POR_SFSI{3,2},POR_SFSI{3,3},POR_SFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, POR_SFAI{3,1},POR_SFAI{3,2},POR_SFAI{3,3},POR_SFAI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, POR_MFSI{3,1},POR_MFSI{3,2},POR_MFSI{3,3},POR_MFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[1, POR_MFAI{3,1},POR_MFAI{3,2},POR_MFAI{3,3},POR_MFAI{3,4}]);
xlabel('Pecentage Noise (%) ');
ylabel('Percentage Overlap Robustness (%)')
set(gca, 'FontSize', 22);

subplot(1,3,3);
plot(100*[0 perturbations],100*[0,T_sum_SFSI{3,1},T_sum_SFSI{3,2},T_sum_SFSI{3,3},T_sum_SFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[0,T_sum_SFAI{3,1},T_sum_SFAI{3,2},T_sum_SFAI{3,3},T_sum_SFAI{3,4}]);
hold on
plot(100*[0 perturbations],100*[0,T_sum_MFSI{3,1},T_sum_MFSI{3,2},T_sum_MFSI{3,3},T_sum_MFSI{3,4}]);
hold on
plot(100*[0 perturbations],100*[0,T_sum_MFAI{3,1},T_sum_MFAI{3,2},T_sum_MFAI{3,3},T_sum_MFAI{3,4}]);
xlabel('Pecentage Noise (%) ');
ylabel('Total Runtime (sec)')
set(gca, 'FontSize', 22);
legend('SFSI','SFAI','MFSI');
