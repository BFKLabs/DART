% --- formats the legend using the formatting data struct, Legend --- %
function hLgOut = createLegendObj(hPlot,Legend,varargin)

% sets the orientation string
oStr = {'vertical','horizontal'};

% converts a handle vector to a handle cell array
if ~iscell(hPlot)
    hPlot = num2cell(hPlot);
end

%
if isfield(Legend,'lgHorz')
    lgHorz = Legend.lgHorz;
    Legend = rmfield(Legend,'lgHorz');
else
    lgHorz = false;
end

% creates the legend
[pOfs,wOfs] = deal(10,0.01);
try
    hLg = legend(cell2mat(hPlot),Legend.String,'Units','pixels',...
                    'location','best','orientation',oStr{1+lgHorz});
catch
    hPlot2 = zeros(size(hPlot));
    for i = 1:length(hPlot); hPlot2(i) = hPlot{i}; end    
    hLg = legend(hPlot2,Legend.String,'Units','pixels',...
                    'location','best','orientation',oStr{1+lgHorz});
end

% resets the legend fonts
set(hLg,'box','off');
hText = findobj(hLg,'type','text');
updateFontProps(hText,Legend.Font,1,'legend');

% % retrieves the position of the text objects
% txtPos = get(hText,'extent');
% if (iscell(txtPos)); txtPos = cell2mat(txtPos); end

% resets the left/bottom location of the legend (placed in the bottom right
% of the plot panel)
lgPos = get(hLg,'position');
hPanel = get(hLg,'parent'); set(hPanel,'Units','pixels');
pPos = get(hPanel,'position'); set(hPanel,'Units','normalized');

% resets the location of the legend to the bottom right
% resetObjPos(hLg,'Width',(max(txtPos(:,1)+txtPos(:,3)) + wOfs))
if (nargin == 2)
    resetObjPos(hLg,'Left',pPos(3)-(pOfs+lgPos(3)))
    resetObjPos(hLg,'bottom',pOfs)
end
    
% resets all the units to pixels
try; set(hLg,'color','none'); end
set(hLg,'units','normalized')

% ensures all the lines in the legend are even in size
set(findobj(hLg,'type','line'),'linewidth',2)

% sets the output variable (if required)
if (nargout == 1); hLgOut = hLg; end