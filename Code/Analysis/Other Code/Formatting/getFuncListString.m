% --- retrieves the analysis plotting function list string array --- %
function fcnStr = getFuncListString(pData)

% retrieves the function type indices
fcnH = {{'Time Independent','Short Experiment','Long Experiment'};...    
        {'Stimuli Independent','Stimuli Dependent'};...
        {'Channel to Sub-Region','Channel to Tube-Region'}};

% fcnH = {'Classic','Stimuli Response','Multi-Metric','Special','Custom'};
fType = setFuncTypeList(pData);
Name = field2cell(pData,'Name');
isFound = false(length(Name),1);

% determines the unique function types
[C,IA,~] = unique(nbase2dec(fType-1,4));

% sets the function strings for all the function types
[fcnStr,iOfs] = deal(repmat({' '},length(C)+length(IA),1),0);
while (any(~isFound))
    % determines the next function type to be found
    i = find(~isFound,1,'first');    
    switch (fType(i,1))
        case (1) % case is the classical functions                        
            % determines the duration type and the matching functions
            dType = fType(i,3);
            [j1,j2] = deal((fType(:,1) == 1),(fType(:,3) == dType));
            
            % sets the new title and the matching functions
            fTitle = sprintf('Classical (%s)',fcnH{1}{dType});
            ii = find(j1 & j2);            
            
        case (2) % case is the non-classical functions
            % determines the stimuli type and the matching functions
            sType = fType(i,2);
            [j1,j2] = deal((fType(:,1) == 2),(fType(:,2) == sType));
            
            % sets the new title and the matching functions
            fTitle = sprintf('Non-Classical (%s)',fcnH{2}{sType});
            ii = find(j1 & j2);                                    
            
        case (3) % case is a specialty function (group altogether)
            [fTitle,ii] = deal('Specialty',find(fType(:,1) == 3));  
            
        case (4) % real-time tracking functions
            % determines the connection type and the matching functions
            sType = fType(i,2);
            [j1,j2] = deal((fType(:,1) == 4),(fType(:,2) == sType));
            
            % sets the new title for the matching functions
            fTitle = sprintf('Real-Time Tracking (%s)',fcnH{3}{sType});
            ii = find(j1 & j2);    
    end
        
    % sets the new title
    fcnStr{iOfs+1} = sprintf(' ====> %s Functions %s',fTitle);
    
    % sets the strings into the overall array
    nNew = length(ii);            
    fcnStr((iOfs+1)+(1:nNew)) = Name(ii);    
    [iOfs,isFound(ii)] = deal(iOfs + (1 + nNew),true);
end

% removes the empty function strings
fcnStr = fcnStr(cellfun(@length,fcnStr)>1);