% --- retrieves the sub-image from the main image, Img --- %
function ImgS = setSubImage(handles,Img)

% global variables
global szDel szDelX szDelY
sz = size(Img);

% retrieves the sub-region data struct
iMov = getappdata(handles.figFlyTrack,'iMov');

% retrieves the current sub-group index
iApp = str2double(get(handles.movCountEdit,'string'));
if isnan(iApp)
    iData = getappdata(handles.figFlyTrack,'iData');
    iApp = iData.cMov;
    
    set(handles.movCountEdit,'string',iApp)
end

% sets the sub-image from the global image
iR = max(1,iMov.iR{iApp}(1)-szDel):min(sz(1),iMov.iR{iApp}(end)+szDel);
iC = max(1,iMov.iC{iApp}(1)-szDel):min(sz(2),iMov.iC{iApp}(end)+szDel);

% determines the x/y local offset
szDelX = iC(1)-iMov.iC{iApp}(1);
szDelY = iR(1)-iMov.iR{iApp}(1);

% sets the sub-image
ImgS = Img(iR,iC);
