% --- updates the location of a single fly marker --- %
function updateIndivMarker(handles,hMark,...
                            hDir,pData,ind,pltLoc,pltAng,forceUpdate) 

% global variables
global isCalib szDelX szDelY
if isempty(pData)
    setObjVisibility(hMark,'off');
    return
end

% sets the default parameters
hFig = handles.figFlyTrack;
if ~exist('forceUpdate','var'); forceUpdate = false; end

% retrieves the sub-region data struct
iMov = get(hFig,'iMov');
if ~iMov.isSet; return; end

% other initialisations
[vStr,hasPhi] = deal({'off','on'},isfield(pData,'PhiF') && ~isCalib);
pltLV = get(handles.checkLocalView,'value');

% retrieves the 
getMarkerProps = get(hFig,'getMarkerProps');
if isCalib || forceUpdate
    isManualReseg = false;
else
    isManualReseg = ~isempty(findall(0,'tag','figManualReseg'));
    cFrm0 = str2double(get(handles.frmCountEdit,'string'));  
    
    % sets the history path frame indices
    cFrm = max(1,cFrm0-(iMov.nPath-1)):cFrm0;
end

cMov = str2double(get(handles.movCountEdit,'string'));
[nFly,isCG] = deal(length(hMark),isColGroup(iMov));

% sets the global/local coordinates and the y-offset 
if pltLV
    % sets the global/local fly locations
%     yOfs = (iMov.iRT{ind(1)}{1}(1)-1); 
    if isCalib || forceUpdate
        pOfs = [(iMov.iC{ind(1)}(1)-1) (iMov.iR{ind(1)}(1)-1)];            
        fPosL = pData{ind(1)} - repmat(pOfs,nFly,1);
        
    else                   
        fPosL = cellfun(@(x)(x(cFrm,:)),pData.fPosL{ind(1)},'un',0);               
        if isCG        
            pOfs = cellfun(@(x)...
                (repmat([x(1)-1,0],length(cFrm),1)),iMov.iCT{ind},'un',0);                                 
        else
            pOfs = cellfun(@(x)...
                (repmat([0,x(1)-1],length(cFrm),1)),iMov.iRT{ind},'un',0);                                
        end
        
        % 
        fPosL = cellfun(@(x,p)(x+p),fPosL,pOfs','un',0);
    end        
else
    % sets the global/local fly locations
    if isCalib || forceUpdate 
        fPos = pData{ind(1)};
    else
        % sets the global/local coordinates and the y-offset 
        
        fPos = cellfun(@(x)(x(cFrm,:)),pData.fPos{ind(1)},'un',0);               
        if isCG
            pOfs = repmat([iMov.iC{ind(1)}(1)-1,0],length(cFrm),1);            
        else
            pOfs = repmat([0,iMov.iR{ind(1)}(1)-1],length(cFrm),1);
        end
        
        % adds on the positional offset
        fPos = cellfun(@(x)(x+pOfs),fPos,'un',0);
    end
end

for i = 1:nFly
    % determines if the local view is being plotted
    if pltLV  
        % sets the local fly coordinates'    
        fPosT = fPosL{i};
        [xFly,yFly] = deal(fPosT(:,1)-szDelX,fPosT(:,2)-szDelY);

        % sets the marker visibility string
        if cMov == ind(1)
            [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
        else
            [vStrNwM,vStrNwA] = deal('off');
        end
    else
        % sets the global fly coordinates
        fPosT = fPos{i};
        [xFly,yFly] = deal(fPosT(:,1),fPosT(:,2));                        

        % sets the marker visibility string
        [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
    end
        
    % otherwise, update the marker locations/visibility
    if isManualReseg
        % retrieves the manual segmentation data struct
        hMR = findobj(0,'tag','figManualReseg');
        mData = getappdata(hMR,'mData');
        pCol = getMarkerProps(handles,iMov,ind,i);    
        
        % determines if any points have been added
        if ~isempty(mData)
            % if so, then determine if this point has been resegmented for
            % this given frame
            [iFrm,iApp,iFly,fPosM,fPosLM] = field2cell(...
                            mData,{'iFrm','iApp','iFly','fPos','fPosL'},1);
            ii = (iFrm == cFrm) & (iApp == ind) & (iFly == i);                        
            if any(ii)
                % marker has been resegmented so reset colour and location
                pCol = 'm';
                if pltLV
                    % use local coordinates
                    yOfs = (iMov.iRT{ind}{i}(1)-1)+szDel;  
                    xFly = fPosLM(ii,1)+szDel;
                    yFly = fPosLM(ii,2)+yOfs;
                else
                    % use global coordinates
                    yOfs = (iMov.iR{ind}(1)-1);
                    [xFly,yFly] = deal(fPosM(ii,1),fPosM(ii,2)+yOfs);                    
                end
            end
        else
            % no segmentation data, so use default colour
            pCol = getMarkerProps(handles,iMov,ind,i);
        end            
        
        % updates the marker
        cellfun(@(x)(set(x,'visible',vStrNwM,'xData',xFly,...
                           'yData',yFly)),hMark(i));
        if strcmp(pCol,'m')
            if ~checkManSegTable(mData,hMark(i),hMR,ind,i,cFrm)
                cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
            end
        else
            cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
        end
    else
        
        % updates the location markers
        set(hMark{i},'visible',vStrNwM,'xData',xFly,'yData',yFly);
        
        % updates the orientation angle markers
        if hasPhi                        
            % retrieves the final angle
            [PhiNw,isF] = deal(pData.PhiF{ind}{i}(cFrm0)*pi/180,true);
            if (isnan(PhiNw))
                % if the final angle isn't set, then retrieve initial angle
                [PhiNw,isF] = deal(pData.Phi{ind}{i}(cFrm0)*pi/180,false);                
            end
            
            % determines if there is a non-NaN orientation angle
            if ~isnan(PhiNw)
                % if so, update the arrow head coordinates
                updateArrowHeadCoords(hDir{i},[xFly,yFly],PhiNw,1,isF); 
                setObjVisibility(hDir{i},vStrNwA)
            else
                % otherwise, make the marker invisible
                setObjVisibility(hDir{i},'off')
            end                        
        end
    end        
end

% --- 
function isUpdate = checkManSegTable(mData,hMark,hMR,iApp,iFly,cFrm)

% retrieves the table object
[hTable,isUpdate] = deal(findobj(hMR,'tag','tableMarkInfo'),false);

% determines the selected row/column of the table
jTable = getappdata(hTable,'jTable');
iRow = jTable.getSelectedRows+1;

% updates the table info
if ~isempty(iRow)
    mD = mData(iRow);
    if (mD.iApp == iApp) && (mD.iFly == iFly) && (mD.iFrm == cFrm)
        set(hMark,'color','k'); isUpdate = true;
    end
end
