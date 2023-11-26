% --- retrieves the sub-image from the main image, Img --- %
function ImgS = setSubImage(handles,Img)

% global variables
global szDel szDelX szDelY
sz = size(Img);

% retrieves the sub-region data struct
iMov = get(handles.figFlyTrack,'iMov');
isMTrk = detMltTrkStatus(iMov);

% retrieves the current sub-group index
iReg = str2double(get(handles.movCountEdit,'string'));
if isnan(iReg)
    iData = get(handles.figFlyTrack,'iData');
    iReg = iData.cMov;    
    set(handles.movCountEdit,'string',iReg)
end

%
if isMTrk
    [iCol,iRow] = ind2sub(size(iMov.flyok),iReg);
    if isempty(iMov.iR{iCol})
        [iR,iC] = deal([]);
    else
        iC = iMov.iC{iCol};
        iR = iMov.iR{iCol}(iMov.iRT{iCol}{iRow});
    end
else
    % case is single-tracking
    [iC,iR] = deal(iMov.iC{iReg},iMov.iR{iReg});
end

% if there is no sub-region data, then exit with an empty image
if isempty(iR) % || ~obj.iMov.ok(iApp)
    ImgS = [];
    return
end

% sets the local x-offset
iCL = max(1,iC(1)-szDel):min(sz(2),iC(end)+szDel);
szDelX = iCL(1)-iC(1);

% sets the local x-offset
iRL = max(1,iR(1)-szDel):min(sz(1),iR(end)+szDel);
szDelY = iRL(1)-iR(1);

% sets the sub-image
ImgS = Img(iRL,iCL,:);