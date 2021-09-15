% --- formats the plot axis, hAx using the plot format data struct, pF, for
%     the subplot index given by the index value, ind
function formatPlotAxis(hAx,pF,ind,varargin)

% retrieves the formatting data struct field names
[pStr,iSub] = deal(sort(fieldnames(pF)),get(hAx,'UserData'));
pStrSub = getStructFields(pF,pStr);

% sets a unique index (if more than one index)
if length(iSub) > 1
    if iscell(iSub)
        iSub = iSub{1};
    else
        iSub = iSub(1);
    end
end

% loops through all of the fields calculating
for i = 1:length(pStr)
    if ~isempty(pStrSub{i})
        hObj = [];

        switch (pStr{i})
            case ('Title') % case is setting the title
                if length(pF.Title) == 1
                    if ~isempty(pF.Title.String)
                        Font = pF.Title.Font;
                        if nargin == 4
                            hObj = title(pF.Title.String);
                        else
                            hObj = title(hAx,pF.Title.String);
                        end
                    end                                        
                else   
                    if ~isnan(ind)
                        if ~isempty(pF.Title(ind).String)
                            Font = pF.Title(ind).Font;
                            if nargin == 4
                                hObj = title(pF.Title(ind).String);
                            else
                                hObj = title(hAx,pF.Title(ind).String);
                            end                        
                        end
                    end
                end
                
            case ('xLabel') % case is the x-axis label
                if length(pF.xLabel) == 1                                 
                    if ~isempty(pF.xLabel.String)
                        % only update if the column index matches the plot                 
                        if iSub == pF.xLabel.ind
                            Font = pF.xLabel.Font;
                            if (nargin == 4)
                                hObj = xlabel(pF.xLabel.String);
                            else
                                hObj = xlabel(hAx,pF.xLabel.String);
                            end
                        end
                    end
                else
                    if ~isempty(pF.xLabel(ind).String)
                        Font = pF.xLabel(ind).Font;
                        if nargin == 4
                            hObj = xlabel(pF.xLabel(ind).String);
                        else
                            hObj = xlabel(hAx,pF.xLabel(ind).String);
                        end
                    end
                end                
                
            case ('yLabel') % case is the 1st y-axis label
                if length(pF.yLabel) == 1
                    if ~isempty(pF.yLabel.String)
                        % only update if the column index matches the plot
                        if iSub == pF.yLabel.ind
                            Font = pF.yLabel.Font;        
                            if (nargin == 4)
                                hObj = ylabel(pF.yLabel.String);
                            else
                                hObj = ylabel(hAx,pF.yLabel.String);
                            end
                        end
                    end
                else
                    if ~isempty(pF.yLabel(ind).String)
                        Font = pF.yLabel(ind).Font;        
                        if (nargin == 4)
                            hObj = ylabel(pF.yLabel(ind).String);
                        else                    
                            hObj = ylabel(hAx,pF.yLabel(ind).String);
                        end
                    end
                end     
                
            case ('zLabel') % case is the 1st y-axis label
                if length(pF.zLabel) == 1
                    if ~isempty(pF.zLabel.String)
                        if iSub == pF.zLabel.ind
                            Font = pF.zLabel.Font;        
                            if (nargin == 4)
                                hObj = zlabel(pF.zLabel.String);
                            else
                                hObj = zlabel(hAx,pF.zLabel.String);
                            end
                        end
                    end
                else
                    if ~isempty(pF.zLabel(ind).String)
                        Font = pF.zLabel(ind).Font;        
                        if (nargin == 4)
                            hObj = zlabel(pF.zLabel(ind).String);
                        else                    
                            hObj = zlabel(hAx,pF.zLabel(ind).String);
                        end
                    end
               end                                 
            case ('Axis') % case is the axis fonts                
                if length(pF.Axis) == 1
                    [hObj,Font] = deal(hAx,pF.Axis.Font);                      
                else
                    [hObj,Font] = deal(hAx,pF.Axis(ind).Font);                      
                end
        end

        % updates the axis font properties
        if ~isempty(hObj) && ~isempty(Font)
            updateFontProps(hObj,Font,ind,pStr{i})        
        end
    end
end

