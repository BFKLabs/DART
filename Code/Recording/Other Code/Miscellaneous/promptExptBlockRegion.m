% --- prompts the user for the region for which to add a new expt block
function iChoice = promptExptBlockRegion(hFig,tLimF,iCh)

% global variables
global yGap

% initialisations
hAx = get(hFig,'CurrentAxes');
% cbFcn = {@getUserClick,hFig};

% removes any 
hBlkPrompt0 = findall(hAx,'tag','hBlkPrompt');
if ~isempty(hBlkPrompt0); delete(hBlkPrompt0); end

%
mStr = 'Select the region where you would like to add the experiment block';
waitfor(msgbox(mStr,'Select Region','modal'))

% turns the axis hold on
hold(hAx,'on')

%
for i = 1:size(tLimF,1)
    % sets the location of the new rectangle object
    rPos = [tLimF(i,1),(iCh(1)-1)+yGap,diff(tLimF(i,:)),range(iCh)+1-yGap];
    
    % creates the imrect object
    hAx = get(hFig,'CurrentAxes');
    hRect = imrect(hAx,rPos);

    % updates the time offset box
    set(hRect,'tag','hBlkPrompt','UserData',i);

    % resets the object properties of the imrect object
    set(findobj(hRect),'uicontextmenu',[])
    setObjVisibility(findobj(hRect,'type','Line'),'off')
    set(findobj(hRect,'type','Patch'),'EdgeColor','g',...
                      'FaceColor',0.95*[1,1,1],'LineWidth',2)
                  
    % creates the constraint function
    yL = [((iCh(1)-1)+yGap),iCh(end)];
    fcnC = makeConstrainToRectFcn('imrect',tLimF(i,:),yL);

    % sets up the api object
    hSig = iptgetapi(hRect);
    hSig.setPositionConstraintFcn(fcnC)                  
end

% turns the axis hold off
hold(hAx,'off')

%
while 1
    w = waitforbuttonpress;
    if w == 0
        iChoice = getUserClick(hFig);
        if isempty(iChoice)
            break
        elseif iChoice > 0
            break
        end
    end
end

%
delete(findall(hAx,'tag','hBlkPrompt'))

% --- 
function iChoice = getUserClick(hFig)

%
hAx = get(hFig,'CurrentAxes');
mPos = get(hFig,'CurrentPoint');
clickType = get(hFig,'SelectionType');

%
if strcmp(clickType,'alt')
    iChoice = [];
elseif isOverAxes(mPos)
    hHover = findAxesHoverObjects(hFig);
    hBlkP = findobj(hHover,'tag','hBlkPrompt');
    
    if isempty(hBlkP)
        iChoice = -1;
    else
        
        iChoice = get(hBlkP,'UserData');
    end
else
    % flag that the user didn't click over the plot axes
    iChoice = -1;
end