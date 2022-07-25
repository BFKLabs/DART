% --- determines if there are any custom signals that are missing
%     from the current signal parameter list
function [sObjC,tStrC] = detCustomSignals(hFig,sTrain)

% initialisations
pType = {'S','L'};
[tStrC,sObjC] = deal([]);

% if there are no stimuli trains, then exit the function
if isempty(sTrain); return; end

% retrieves the current signal tab titles
hTabS = getappdata(hFig,'hTabS');
tStrS = cellfun(@(x)(x.Title),hTabS,'un',0);

%
for i = 1:length(pType)
    % retrieves the protocol stimuli train
    sTrainP = getStructField(sTrain,pType{i});
    if ~isempty(sTrainP)
        % loops through each stimuli train determining if there
        % are any signal objects generated with custom signals
        for j = 1:length(sTrainP)
            % retrieves the stimuli train parameters/types
            if iscell(sTrainP)
                blkInfo = sTrainP{j}.blkInfo;
            else
                blkInfo = sTrainP(j).blkInfo;
            end            
            
            % determines if there are any missing signal types
            [tStrNw,sP] = field2cell(blkInfo,{'sType','sPara'});            
            isNw = find(cellfun(@(x)(~(any(strcmp(tStrS,x)) || ....
                                    any(strcmp(tStrC,x)))),tStrNw(:)));
            if any(isNw)
                % retrieves the signal objects
                sObjNw = cellfun(@(x)(x.sObj),sP(isNw),'un',0);
                
                % determines the new unique signal types that
                % are too be added to the tab list
                [tStrNw,iB] = unique(tStrNw(isNw));
                
                % updates the tab title/signal object arrays
                tStrC = [tStrC;tStrNw];
                sObjC = [sObjC;sObjNw(iB)];
            end
        end
    end
end
