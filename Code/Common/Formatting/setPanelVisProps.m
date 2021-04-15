% --- sets the enabled properties for all the objects within a panel --- %
function setPanelVisProps(hPanel,eType)

% retrieves the panel children objects
hChild = get(hPanel,'Children');

% loops through all the panel objects setting the enabled properties
for i = 1:length(hChild)
    switch (get(hChild(i),'type'))
        case {'uipanel','axes','uitabgroup','uitab'}
            % no enabled properties for panel objects
        otherwise
            % sets the panel enabled type
            setObjVisibility(hChild(i),eType);            
    end    
end