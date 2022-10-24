% --- sets the enabled properties for all the objects within a panel --- %
function setPanelProps(hPanel,eType,varargin)

% converts any logical/numerical values to strings
if islogical(eType) || isnumeric(eType)
    eStr = {'off','on'};
    eType = eStr{double(eType)+1};
end

% retrieves the panel children objects
[updatePanel,nonHandle] = deal(false,{-1});
[tCol,dCol] = deal(0.71*[1 1 1],0.941*[1 1 1]);
hChild = get(hPanel,'Children');
hList = findobj(hChild,'style','listbox');
hText = findobj(hChild,'style','text');

% sets the other fields
if nargin > 2 
    % determines if the input is a handle
    if isnumeric(varargin{1})
        % if so, flag that the panel is not to be updated
        updatePanel = false;
    elseif ishandle(varargin{1})
        % otherwise, these are the handles to ignore
        nonHandle = num2cell(varargin{1});        
    end
else
    updatePanel = ~strcmp(get(hPanel,'type'),'uitab');
end

% loops through all the panel objects setting the enabled properties
for i = 1:length(hChild)   
    if ~any(cellfun(@(x)(x == hChild(i)),nonHandle))   
        switch get(hChild(i),'type')
            case {'uitabgroup'}                                
                % retrieves the java tab object
                jTab = getappdata(hChild(i),'UserData');
                    
                hTab = get(hChild(i),'Children');
                for j = 1:length(hTab)
                    if nargin > 2
                        p = varargin;
                        setPanelProps(hTab(j),eType,p)
                    else
                        setPanelProps(hTab(j),eType)
                    end

                    if ~isempty(jTab)
                        jTab.setEnabledAt(j-1,strcmp(eType,'on'))        
                    end                         
                end
                
            case {'axes','uibuttongroup','uicontainer'}
                % no enabled properties for panel objects
                
            case ('uipanel')
                if strcmp(eType,'on')
                    set(hChild(i),'foregroundcolor',[0 0 0])
                else
                    set(hChild(i),'foregroundcolor',tCol)
                end 
                
            otherwise
                if any(hChild(i) == hList)
                    setObjEnable(hChild(i),eType)
                    if strcmp(eType,'on')
                        set(hChild(i),'backgroundcolor',[1 1 1])
                    else
                        set(hChild(i),'backgroundcolor',dCol)
                    end  
                    
                elseif any(hChild(i) == hText)
                    if isempty(get(hChild(i),'string'))
                        setObjEnable(hChild(i),eType)
                        if strcmp(eType,'on')
                            set(hChild(i),'backgroundcolor',[1 1 1])
                        else
                            set(hChild(i),'backgroundcolor',dCol')
                        end                                                 
                    else
                        % sets the panel enabled type
                        setObjEnable(hChild(i),eType);
                    end
                else
                    % sets the panel enabled type
                    setObjEnable(hChild(i),eType);               
                end
        end    
    end    
end

% sets the panel text colour based on the enabled properties
if updatePanel
    if strcmp(eType,'on')
        set(hPanel,'foregroundcolor',[0 0 0])
    else
        set(hPanel,'foregroundcolor',tCol)
    end
end