% Author:       Mixon, Villar, Ward.
% Filename:     main.m
% Last edited:  9 May 2016 
% Description:  Runs Peng and Wei's kmeans SDP [4] (using SDPNAL+ [5]) 
%               and Matlab's built in kmeans++ version of Lloyd's algorithm
%               on NMIST data [2] 
%               previously preprocessed using TensorFlow [1] (mapped into
%               feature space and saved in './data/data_features.mat')
%               This procedure prints out a numerical comparison and 
%               produces the graphs in [3]).
%               Requires CVX [6] and SDPNAL+0.3 (CVX is only required for 
%               misclassification.m)
%
% Inputs:       
%               
% Outputs:        
% 
% References:
% [1] Abadi et al. TensorFlow: Large-scale machine learning on 
%       heterogeneous systems.
% [2] LeCun, Cortes. Mnist handwritten digit database.
% [3] Mixon, Villar, Ward. Clustering subgaussian mixtures via semidefinite
%       programming
% [4] Peng, Wei. Approximating k-means-type clustering via semidefinite 
%       programming.
% [5] Yang, Sun, Toh. Sdpnal+: a majorized semismooth newton-cg augmented
%       lagrangian method for semidefinite programming with nonnegative 
%       constraints.
% [6] CVX Research, Inc. CVX: Matlab Software for Disciplined Convex 
%       Programming
% -------------------------------------------------------------------------

%loading data from file
[digits,labels]=get_data();

k=max(labels);
N=size(labels,1);

disp('planted clusters')
misclassification_rate=0
kmeans_value=value_kmeans(digits, labels)


disp('SDP clustering')
%XX=kmeans_sdp(digits, k);
denoised=digits*XX;
[centers, sdp_labels]=sdp_rounding(denoised, k);
misclassification_rate=misclassification(labels, sdp_labels)
kmeans_value= value_kmeans(digits, sdp_labels)


disp('lloyds clustering')
mis=zeros(100,1);
vals=zeros(100,1);
for i=1:100
    [lloyd_labels, ~]=kmeans(digits',k);
    mis(i)=misclassification(labels, lloyd_labels);
    vals(i)=value_kmeans(digits, lloyd_labels);
end
worst_misclassification_rate=max(mis)
worst_kmeans_value=max(vals)
best_misclassification_rate=min(mis)
best_kmeans_value=min(vals)
frequency_best=sum(abs(mis-best_misclassification_rate*ones(100,1))<1e-6)

% graphs 
figure(1)
hold off
imagesc(XX)
title('SDP solution')
colormap('gray')
colormap(flipud(colormap));
set(gca,'xtick',[])
set(gca,'ytick',[])
axis equal
a=axis;
a(1)=a(3);
a(2)=a(4);
axis(a)

% project points into a random plane to graph them
G=randn(2,k);
Pce=G*centers';
Pde=G*denoised;
Pdi=G*digits;

figure(3)
hold off
scatter(Pdi(1,:), Pdi(2,:), 'k.')
hold on
scatter(Pce(1,:), Pce(2,:),100,'ro', 'LineWidth',3)
title('Digit features')
set(gca,'xtick',[])
set(gca,'ytick',[])
box on
axis equal
a=axis;
a(3)=a(1);
a(4)=a(2);
axis(a);

figure(2)
hold off
scatter(Pde(1,:)+0.01*randn(1,N), Pde(2,:)+0.01*randn(1,N), 'k.')
hold on
scatter(Pce(1,:), Pce(2,:),100,'ro', 'LineWidth',3)
title('Digit features after SDP denoising')
set(gca,'xtick',[])
set(gca,'ytick',[])
box on
axis equal
axis(a);




disp('lower bound from SDP:')
D = zeros(N,N);
for ii=1:N
    for jj=1:N
        D(ii,jj) = norm(digits(:,ii)-digits(:,jj))^2;
    end
end
lower_bound= trace(D*XX)/2
