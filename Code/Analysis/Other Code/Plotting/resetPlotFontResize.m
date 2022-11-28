% --- 
function [hAxT,hLg,m,n] = resetPlotFontResize(hPanel,pData)

% global variables
global regSz

% initialisations
pF = pData.pF;
[uStr,hAxObj] = deal(get(hPanel,'Units'),findall(hPanel,'type','axes'));
lStr = {'Title','xLabel','yLabel','zLabel'};

% splits the axes handles into plot and legend axes
ii = strcmp(get(hAxObj,'tag'),'legend');
[hAx,hLg] = deal(hAxObj(~ii),hAxObj(ii));

% retrieves the panel position (in pixels)
set(hPanel,'Units','Pixels')
newSz = get(hPanel,'position');
set(hPanel,'Units',uStr)

% retrieves the axis child objects
hChild = get(hAx,'Children');
if (~iscell(hChild)); hChild = {hChild}; end

% removes the x/y labels axes from the list
jj = strcmp(get(hAx,'tag'),'xLabel') | strcmp(get(hAx,'tag'),'yLabel') | ...
     strcmp(get(hAx,'tag'),'zLabel') | cellfun('isempty',hChild);
hAxT = hAx(~jj);

% determines the number of subplot axis
if (length(hAxT) == 1)
    % only one axis
    [m,n] = deal(1);
else
    % sets the row/column count
    axPos = cell2mat(get(hAxT,'position'));
    kk = all(axPos(:,3:4) < 1,2);
    [axPos,hAxT] = deal(axPos(kk,:),hAxT(kk));
    
    % determines the unique locations
    [aX,~,iC] = unique(roundP(axPos(:,1),0.05));
    [aY,~,iR] = unique(roundP(axPos(:,2),0.05));
    
    % sets the subplot dimensions and sorts by location
    [m,n] = deal(length(aY),length(aX));
    [~,jj] = sort(sum([10*(m-(iR-1)),iC],2));    
    hAxT = hAxT(jj);
end  

% determines the font ratio
fR = min(newSz(3:4)./regSz(3:4))*get(0,'ScreenPixelsPerInch')/72;

% reformats the font data struct for the subplot count
if (isempty(m)); szMx = 1; else szMx = max([m n]); end
pF = retFormatStruct(pF,szMx);
    
% updates
for i = 1:length(hAx)    
    % updates the fonts for each of the labels
    for j = 1:length(lStr)
        pFF = eval(sprintf('pF.%s',lStr{j}));
        switch (lStr{j})
            case {'xLabel','yLabel','zLabel'}                
                if (strcmp(get(hAx(i),'tag'),lStr{j}))
                    hLbl = findall(hAx(i),'tag','multiLbl');
                    updateFontSize(hLbl,pFF,fR,lStr{j})
                else
                    hLbl = get(hAx(i),lStr{j});
                    if (strcmp(get(hLbl,'visible'),'on'))
                        updateFontSize(hLbl,pFF,fR,lStr{j})
                    end
                end
            otherwise
                updateFontSize(get(hAx(i),lStr{j}),pFF,fR,lStr{j})
        end
    end
    
    % updates the other objects
    updateFontSize(findall(hAx(i),'tag','Other'),pF.Axis,fR,'Other')
    
    % retrieves the rotated text objects
    hText = findall(hAx(i),'type','text');    
    if (~isempty(hText))
        tPos = get(hText,'Rotation');
        if (iscell(tPos)); tPos = cell2mat(tPos); end        
    
        % updates the font size for the axis object
        hText = hText((tPos ~= 0) & cellfun('isempty',get(hText,'tag')));
        for j = 1:length(hText)
            updateFontSize(hText(j),pF.Axis,fR,'text')    
        end
    end
    
    % updates the font size for the axis object
    updateFontSize(hAx(i),pF.Axis,fR,'axes')    
end

%
for i = 1:length(hLg)    
    % updates the font size for the axis object    
    updateFontSize(hLg(i),pF(i).Legend,fR,'legend')    
end

% --- 
function updateFontSize(hObj,pFF,fR,type)    

%
fSzNw = setMinFontSize(pFF(1).Font.FontSize*fR,type);

% updates the font size 
set(hObj,'FontUnits','Pixels');
set(hObj,'FontSize',fSzNw);

