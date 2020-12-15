% --- updates the location of a single fly marker --- %
function updateIndivMarker(handles,hMark,hDir,pData,ind,pltLoc,pltAng,forceUpdate) 

% global variables
global isCalib szDelX szDelY
if (isempty(pData))
    try; set(hMark,'visible','off'); end
    return
end

% sets the default parameters
if ~exist('forceUpdate','var'); forceUpdate = false; end

% other initialisations
[vStr,hasPhi] = deal({'off','on'},isfield(pData,'PhiF') && (~isCalib));
pltLV = get(handles.checkLocalView,'value');

% retrieves the 
getMarkerProps = getappdata(handles.figFlyTrack,'getMarkerProps');
if (isCalib || forceUpdate)
    isManualReseg = false;
else
    isManualReseg = ~isempty(findall(0,'tag','figManualReseg'));
    cFrm = str2double(get(handles.frmCountEdit,'string'));  
end

% retrieves the sub-region data struct
iMov = getappdata(handles.figFlyTrack,'iMov');
if ~iMov.isSet; return; end

cMov = str2double(get(handles.movCountEdit,'string'));
[nFly,isCG] = deal(length(hMark),isColGroup(iMov));

% sets the global/local coordinates and the y-offset 
if (pltLV)
    % sets the global/local fly locations
%     yOfs = (iMov.iRT{ind(1)}{1}(1)-1); 
    if (isCalib || forceUpdate)
        pOfs = [(iMov.iC{ind(1)}(1)-1) (iMov.iR{ind(1)}(1)-1)];            
        fPosL = pData{ind(1)} - repmat(pOfs,nFly,1);
    else                   
        fPosL = cell2mat(cellfun(@(x)(x(cFrm,:)),pData.fPosL{ind(1)},'un',0)');               
        if (isCG)        
            fPosL(:,1) = fPosL(:,1) + cellfun(@(x)(x(1)-1),iMov.iCT{ind});                                
        else
            fPosL(:,2) = fPosL(:,2) + cellfun(@(x)(x(1)-1),iMov.iRT{ind});                                
        end
    end        
else
    % sets the global/local fly locations
    if (isCalib || forceUpdate)    
        fPos = pData{ind(1)};
    else
        % sets the global/local coordinates and the y-offset 
        fPos = cell2mat(cellfun(@(x)(x(cFrm,:)),pData.fPos{ind(1)},'un',0)');               
        if (isCG)
            fPos(:,1) = fPos(:,1) + (iMov.iC{ind(1)}(1)-1);
        else
            fPos(:,2) = fPos(:,2) + (iMov.iR{ind(1)}(1)-1);
        end
    end
end

for i = 1:nFly
    % determines if the local view is being plotted
    if (pltLV)                
        % sets the local fly coordinates'        
        [xFly,yFly] = deal(fPosL(i,1)-szDelX,fPosL(i,2)-szDelY);

        % sets the marker visibility string
        if (cMov == ind(1))
            [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
        else
            [vStrNwM,vStrNwA] = deal('off');
        end
    else
        % sets the global fly coordinates
        [xFly,yFly] = deal(fPos(i,1),fPos(i,2));                        

        % sets the marker visibility string
        [vStrNwM,vStrNwA] = deal(vStr{(pltLoc)+1},vStr{(pltAng)+1});
    end
        
    % otherwise, update the marker locations/visibility
    if (isManualReseg)
        % retrieves the manual segmentation data struct
        hMR = findobj(0,'tag','figManualReseg');
        mData = getappdata(hMR,'mData');
        pCol = getMarkerProps(iMov,ind,i);    
        
        % determines if any points have been added
        if (~isempty(mData))
            % if so, then determine if this point has been resegmented for
            % this given frame
            [iFrm,iApp,iFly,fPosM,fPosLM] = field2cell(...
                            mData,{'iFrm','iApp','iFly','fPos','fPosL'},1);
            ii = (iFrm == cFrm) & (iApp == ind) & (iFly == i);                        
            if (any(ii))
                % marker has been resegmented so reset colour and location
                pCol = 'm';
                if (pltLV)
                    % use local coordinates
                    yOfs = (iMov.iRT{ind}{i}(1)-1)+szDel;                 
                    [xFly,yFly] = deal(fPosLM(ii,1)+szDel,fPosLM(ii,2)+yOfs);
                else
                    % use global coordinates
                    yOfs = (iMov.iR{ind}(1)-1);
                    [xFly,yFly] = deal(fPosM(ii,1),fPosM(ii,2)+yOfs);                    
                end
            end
        else
            % no segmentation data, so use default colour
            pCol = getMarkerProps(iMov,ind,i);
        end            
        
        % updates the marker
        cellfun(@(x)(set(x,'visible',vStrNwM,'xData',xFly,'yData',yFly)),hMark(i));
        if (strcmp(pCol,'m'))
            if (~checkManSegTable(mData,hMark(i),hMR,ind,i,cFrm))
                cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
            end
        else
            cellfun(@(x)(set(x,'Color',pCol)),hMark(i))
        end
    else
        %
%         if (iMov.rot90)
%             j = (nFly+1) - i;
%         else
%             j = i;
%         end
        
        % updates the location markers
        set(hMark{i},'visible',vStrNwM,'xData',xFly,'yData',yFly);
        
        % updates the orientation angle markers
        if (hasPhi)                        
            % retrieves the final angle
            [PhiNw,isF] = deal(pData.PhiF{ind}{i}(cFrm)*pi/180,true);
            if (isnan(PhiNw))
                % if the final angle isn't set, then retrieve initial angle
                [PhiNw,isF] = deal(pData.Phi{ind}{i}(cFrm)*pi/180,false);                
            end
            
            % determines if there is a non-NaN orientation angle
            if (~isnan(PhiNw))
                % if so, update the arrow head coordinates
                updateArrowHeadCoords(hDir{i},[xFly,yFly],PhiNw,1,isF); 
                set(hDir{i},'visible',vStrNwA)
            else
                % otherwise, make the marker invisible
                set(hDir{i},'visible','off')
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
row = jTable.getSelectedRows+1;

% updates the table info
if (~isempty(row))
    mD = mData(row);
    if ((mD.iApp == iApp) && (mD.iFly == iFly) && (mD.iFrm == cFrm))
        set(hMark,'color','k'); isUpdate = true;
    end
end
