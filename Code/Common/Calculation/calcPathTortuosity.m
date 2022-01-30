function [T,Dtot,DstpMx,Deuc] = calcPathTortuosity(X,Y,N)

% initialisations
nFrm = length(X);
ind = buffer(1:nFrm,N,N-1); 

% converts the vectors to overlapping blocks
[XX,YY] = deal(X(ind(:,N:end))',Y(ind(:,N:end))'); 
DstpMx = max(sqrt(diff(XX,[],2).^2 + diff(YY,[],2).^2),[],2);

% calculates the displacement/distances for each grouping
Dtot = sum(sqrt(diff(XX,[],2).^2 + diff(YY,[],2).^2),2);
Deuc = sqrt(diff(XX(:,[1,end]),[],2).^2 + diff(YY(:,[1,end]),[],2).^2);

% calculates the tortuosity (ratio of displacement to distance)
T = Deuc./Dtot;
