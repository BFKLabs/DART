% --- calculates the sub-image reflection type classifier SVM's
function [svm,iClass] = setupReflectSVMClassifier2D()

% sets the directory file name
dFile = 'E:\Work\Code\DART\Program\Test Files\2D';

% retrieves the m-file names
mFile = dir(fullfile(dFile,'*.mat'));
mName = field2cell(mFile,'name');
nFile = length(mName);

% creates the waitbar figure
wStr = {'Overall Progress','Current File Progress'};
h = waitbarFig(wStr,'Reflection Glare Stats Setup');

% data struct memory allocation
a = struct('dILmx',[],'dILmn',[]);
pMet = repmat(a,1,2);

% memory allocation
[dILmx,dILmn,rT] = deal(cell(nFile,1));

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
    rT{i} = rType(:,:,ii);
    
    % determines the low-variance phases        
    sz = size(rType);
    [dILmx{i},dILmn{i}] = deal(zeros([sz(1:2),length(ii)]));
    for j = 1:length(ii)
        % updates the waitbar figure
        wStrNw = sprintf('%s (Phase %i of %i)',wStr{2},j,length(ii));
        if (waitbarFig(2,wStrNw,j/length(ii),h))
            return
        end          
        
        % calculates the metrics for each phase
        [dILmx{i}(:,:,j),dILmn{i}(:,:,j)] = ...
                                calcPhaseStats2D(iMov,sImg(ii(j)).I,rOK);
    end
    
    %
    [A,B,C] = deal(max(dILmx{i},[],3),max(dILmn{i},[],3),max(rT{i},[],3));
    for j = 1:length(pMet)
        for iR = 1:size(A,1)
            for iC = 1:size(A,2)
                k = (C(iR,iC) > 1) + 1;
                pMet(k).dILmx = [pMet(k).dILmx,A(iR,iC)];
                pMet(k).dILmn = [pMet(k).dILmn,B(iR,iC)];
            end
        end
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
xi = num2cell(1:length(pMet));

% initialisations
[dILmxC,dILmnC] = field2cell(pMet,{'dILmx','dILmn'});
Grp = cellfun(@(x,y)(y*ones(length(x),1)),dILmxC,xi,'un',0)';

% sets up the training data for the svm classifier
Xnw = [[cell2mat(dILmxC);cell2mat(dILmnC)],[-100;-100]]';
Grp = [cell2mat(Grp);1];

% trains the svm classifier for each grouping
svm = svmtrain(Xnw,Grp,'kernel_function','linear'); 

% classifies the data
iClass = cell(nFile,1);
for i = 1:nFile
    iClass{i} = classReflectStats(svm,dILmx{i},dILmn{i});    
end




