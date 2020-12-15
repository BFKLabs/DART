% --- calculates the sub-image reflection type classifier SVM's
function [svm,iClass] = setupReflectSVMClassifier1D()

% sets the directory file name
dFile = 'E:\Work\Code\DART\Program\Test Files\1D';

% retrieves the m-file names
mFile = dir(fullfile(dFile,'*.mat'));
mName = field2cell(mFile,'name');
nFile = length(mName);

% creates the waitbar figure
wStr = {'Overall Progress','Current File Progress'};
h = waitbarFig(wStr,'Reflection Glare Stats Setup');

% data struct memory allocation
a = struct('s',[],'mu',[],'dI',[]);
pMet = repmat(a,1,3);

% memory allocation
[sC,muC,dIC] = deal(cell(nFile,1));

% calculates the metrics for each of the files
for i = 1:nFile
    % updates the waitbar figure
    wStrNw = sprintf('%s (File %i of %i)',wStr{1},i,nFile);
    if (waitbarFig(1,wStrNw,i/(1+nFile),h))
        return
    else
        waitbarFig(2,wStr{2},0,h);
    end    

    % sets the full m-file name
    mFileNw = fullfile(dFile,mName{i});
    load(mFileNw);  
    
    ii = find(iMov.vPhase == 1)';
    rT{i} = rType(ii,:);
    
    % determines the low-variance phases        
    [sC{i},muC{i},dIC{i}] = deal(zeros(length(ii),size(rType,2)));
    for j = 1:length(ii)
        % updates the waitbar figure
        wStrNw = sprintf('%s (Phase %i of %i)',wStr{2},j,length(ii));
        if (waitbarFig(2,wStrNw,j/length(ii),h))
            return
        end          
        
        % calculates the metrics for each phase
        [sC{i}(j,:),muC{i}(j,:),dIC{i}(j,:),pMet] = ...
            calcPhaseStats1D(iMov,sImg(ii(j)).I,rOK,rType(ii(j),:),pMet);
    end
end

% updates and closes the waitbar figure
if (~waitbarFig(1,'Test File Setup Complete',1,h))
    close(h)
end

% ---------------------------- %
% --- SVM CLASSIFIER SETUP --- %
% ---------------------------- %

% parameters
sTol = 0.25;

% initialisations
[s,mu,dI] = field2cell(pMet,{'s','mu','dI'});
Grp = cellfun(@(x,y)(y*ones(length(x),1)),s,num2cell(1:length(s)),'un',0)';
svm = cell(length(s)-1,1);

% sets up the training data for the svm classifier
ZNw = [cell2mat(s);cell2mat(mu);cell2mat(dI)]';
[Grp12,Grp23] = deal(min(2,cell2mat(Grp)),max(2,cell2mat(Grp)));

% trains the svm classifier for each grouping
svm{1} = svmtrain(ZNw,Grp12,'kernel_function','rbf','rbf_sigma',sTol);
svm{2} = svmtrain(ZNw,Grp23,'kernel_function','rbf','rbf_sigma',sTol);
svm = cell2mat(svm);

% classifies the data
iClass = cell(nFile,1);
for i = 1:nFile
    iClass{i} = classReflectStats(svm,sC{i},muC{i},dIC{i});    
end




