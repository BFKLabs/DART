% --- prompts the user for the region for which to add a new expt block
function iChoice = promptExptBlockRegion(hFig,tLimF,iCh)

% global variables
global yGap

% initialisations
lWid = 2;
fCol = 0.95*[1,1,1];
hAx = get(hFig,'CurrentAxes');
% cbFcn = {@getUserClick,hFig};

% removes any 
hBlkPrompt0 = findall(hAx,'tag','hBlkPrompt');
if ~isempty(hBlkPrompt0); delete(hBlkPrompt0); end

% prompts the user to select the block to add to
mStr = 'Select the region where you would like to add the experiment block';
waitfor(msgbox(mStr,'Select Region','modal'))

% turns the axis hold on
hold(hAx,'on')

% creates prompt blocks for each section limit
for i = 1:size(tLimF,1)
    % sets the location of the new rectangle object
    rPos = [tLimF(i,1),(iCh(1)-1)+yGap,diff(tLimF(i,:)),range(iCh)+1-yGap];
    
    % creates the rectangle object
    hAx = get(hFig,'CurrentAxes');
    hRect = InteractObj('rect',hAx,rPos);
    hRect.setFields('tag','hBlkPrompt','UserData',i);

    % creates the constraint function
    yL = [((iCh(1)-1)+yGap),iCh(end)];
    hRect.setConstraintRegion(tLimF(i,:),yL);    
    
    % resets the object properties of the rectangle object
    if hRect.isOld
        % case is an older interactive object format
        hObjR = hRect.hObj;
        set(findobj(hObjR),'uicontextmenu',[])
        setObjVisibility(findobj(hObjR,'type','Line'),'off')
        set(findobj(hObjR,'type','Patch'),'EdgeColor','g',...
                          'FaceColor',fCol,'LineWidth',lWid)
    else
        % case is a newer interactive object format
        hRect.setFields('EdgeColor','g','FaceColor',fCol,...
                        'LineWidth',lWid,'uicontextmenu',[]);
    end
end

% turns the axis hold off
hold(hAx,'off')

% wait for the next user key press
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

% deletes any prompt block objects
delete(findall(hAx,'tag','hBlkPrompt'))

% --- determines the users selection
function iChoice = getUserClick(hFig)

% field retrieval
mPos = get(hFig,'CurrentPoint');
clickType = get(hFig,'SelectionType');

% determines if the user is currently holding the alt-key
if strcmp(clickType,'alt')
    % if holding the alt key, then return an empty choice (clears choice)
    iChoice = [];
    
elseif isOverAxes(mPos)
    % determines if the user is hovering over a block prompt object
    hHover = findAxesHoverObjects(hFig);
    hBlkP = findobj(hHover,'tag','hBlkPrompt');    
    if isempty(hBlkP)
        % if not, then return an error index flag
        iChoice = -1;
    else
        % otherwise, return the index of the selected block
        iChoice = get(hBlkP,'UserData');
    end
else
    % flag that the user didn't click over the plot axes
    iChoice = -1;
end