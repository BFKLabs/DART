% --- cell segmentation summary function
function sigD = SegSummary(sigD,Type,iLvl,iCell)

%
if (nargin < 1); sigD = []; end

%
if (isempty(sigD))
    % retrieves the program default directory file data struct
    ProgDef = getappdata(findall(0,'tag','figGCamp'),'ProgDef');

    % prompts the user for the summary file
    [fName,fDir,fIndex] = uigetfile({'*.mat','Matlab File (*.mat)'},...
                            'Open Signal Data File',ProgDef.Tracking.DirMov);
    if (fIndex == 0)
        % if the user cancelled, then exit
        sigD = [];
        return
    else
        % creates a loadbar and opens the file
        hLB = ProgressLoadbar('Loading Summary File...');
        A = load(fullfile(fDir,fName));
        try; delete(hLB); end; pause(0.05);
        
        % determines if the file is valid
        if (~isfield(A,'sigD'))
            % if not, then exit with an error
            sigD = [];
            eStr = 'Error! Selected file is not a valid signal data file.';
            waitfor(errordlg(eStr,'Incorrect Signal Data File','modal'))
            return
        else
            % otherwise, convert the cell array to a struct array
            sigD = cell2mat(A.sigD);
        end
    end
end

% if the type has not been specified, then exit
if (nargin < 2); return; end
    
%
switch (Type)
    case ('Info') % case is outputting the cell info
        dispCellInfo(sigD)
    case ('Average') % case is plotting the average trace
        switch (nargin)
            case (2)
                % use all the signals
                iLvl = 1:length(sigD);                
            case (3)
                if (any(iLvl > length(sigD)))
                    eStr = 'Error! The level indices exceed the total number of levels';
                    waitfor(errordlg(eStr,'Incorrect Level Indices','modal'))
                    return                
                end
            otherwise
                eStr = 'Error! Incorrect number of function input arguments';
                waitfor(errordlg(eStr,'Incorrect Input Arguments','modal'))
                return                                
        end
        
        % otherwise, plot the average baseline signal
        plotCellData(field2cell(sigD(iLvl),'muFrm'),Type,iLvl)        
    case ('Cell') % case is plotting the cell traces
        %
        Ysig = field2cell(sigD,'Ysig');        
        nSig = cellfun(@(x)(size(x,2)),Ysig,'UniformOutput',0);
        
        switch (nargin)
            case (2)
                % use all the signals
                iLvl = (1:length(sigD))';                                
                iCell = cellfun(@(x)(1:x),nSig,'UniformOutput',0);
            case (3)
                iLvl = reshape(iLvl,length(iLvl),1);
                iCell = cellfun(@(x)(1:x),nSig(iLvl),'UniformOutput',0);
            case (4)
                if (length(iLvl) ~= length(iCell))
                    eStr = 'Error! Incorrect number of function input arguments';
                    waitfor(errordlg(eStr,'Incorrect Input Arguments','modal'))
                    return                                                    
                elseif (length(iLvl) == 1)
                    iCell = {iCell};     
                else
                    iLvl = reshape(iLvl,length(iLvl),1);
                    iCell = reshape(iCell,length(iCell),1);
                end
            otherwise
                eStr = 'Error! Incorrect number of function input arguments';
                waitfor(errordlg(eStr,'Incorrect Input Arguments','modal'))
                return                                
        end
                
        % sets the         
        Y = cellfun(@(x,y)(x(:,y)),Ysig(iLvl),iCell,'UniformOutput',0);
                
        % runs the plotting function
        plotCellData(Y,Type,iLvl,iCell)        
        
    otherwise % incorrect argument type
        eStr = 'Error! Type arguments must be either "Info", "Average" or "Cell".';
        waitfor(errordlg(eStr,'Incorrect Function Argument','modal'))
end

% --- display the cell data within a figure
function plotCellData(Y,Type,iLvl,iCell) 

% 
if (nargin == 3); iCell = []; end
[nLvl,fig] = deal(length(Y),figure('position',[300 300 800 600]));
hold on;

%
switch (Type)
    case ('Average')
        tStr = sprintf('Average Pixel Intensity (Level %i)',iLvl(1));
        plot(Y{1},'tag','hPlot');
        
    case ('Cell')        
        %
        tStr = sprintf('Cell Pixel Intensity (Level %i)',iLvl(1));        
        nPlot = max(cellfun(@(x)(size(x,2)),Y));                
        cellfun(@(x)(plot(NaN,'tag','hPlot','UserData',x)),num2cell(1:nPlot));        
        
        dcObj = datacursormode(fig);
        set(setObjEnable(dcObj,'on'),'UpdateFcn',{@dcUpdateFcn,fig,iCell});        
        
        for i = 1:size(Y{1},2)
            hPlot = findall(gca,'tag','hPlot','UserData',i);
            set(hPlot,'ydata',Y{1}(:,i))
        end
end

% sets the axis properties
title(tStr,'FontSize',24,'FontWeight','bold')
xlabel('Frame Index','FontSize',20,'FontWeight','bold')
ylabel('Pixel Intensity','FontSize',20,'FontWeight','bold')
set(gca,'FontSize',16,'FontWeight','bold','xlim',[1 size(Y{1},1)])

% sets the key press function
if nLvl > 1
    % removes the window listener handle
    hManager = uigetmodemanager(fig);
    try
        setObjEnable(hManager.WindowListenerHandles);  % HG1
    catch
        [hManager.WindowListenerHandles.Enabled] = deal(false);  % HG2
    end        
    
    set(fig,'WindowKeyPressFcn',{@keyPressFcn,Y,Type,iLvl,iCell},'UserData',1)
end

% --- callback function for the the data cursor object
function outText = dcUpdateFcn(~,event,fig,iCell)

% determines the plot/level that was selected
[iPlot,iSel] = deal(get(get(event,'Target'),'UserData'),get(fig,'UserData'));

% sets the tool-tip string
outText = sprintf('Cell #%i',iCell{iSel}(iPlot));

% --- callback function for key pressing function
function keyPressFcn(obj,event,Y,Type,iLvl,iCell)

% determines the currently displayed level
iSel = get(obj,'UserData');

% determines the action based on the key being pressed
switch (event.Key)
    case ('leftarrow') % case is pressing the left arrow
        if (iSel == 1)
            return
        else
            iSelNw = iSel - 1;            
        end
        
    case ('rightarrow') % case is pressing the left arrow
        if (iSel == length(Y))
            return
        else
            iSelNw = iSel + 1;            
        end
    otherwise
        return
end
        
% updates the index
hPlot = findall(gca,'type','line');

% set/updates the properties based on the plot type
switch (Type)
    case ('Average') % case is the base line average       
        set(hPlot,'ydata',Y{iSelNw})
        tStr = sprintf('Average Pixel Intensity (Level %i)',iLvl(iSelNw));        
        
    case ('Cell') % case is the cell data
        
        tStr = sprintf('Cell Pixel Intensity (Level %i)',iLvl(iSelNw));        
        
        setObjVisibility(hPlot,'off')
        for i = 1:length(iCell{iSelNw})
            hPlotNw = findall(hPlot,'UserData',i);
            set(setObjVisibility(hPlotNw,'on'),'ydata',Y{iSelNw}(:,i));
        end                
end

% sets the new title string
set(get(gca,'Title'),'String',tStr)
set(obj,'UserData',iSelNw);
uistack(gcf,'top')

% --- displays the cell information to screen
function dispCellInfo(sigD)

% determines the number of cells/level
nGrp = cellfun(@length,field2cell(sigD,'pGrp'));

% initialisations
[A,a] = deal('% Level % Count %',char(37));
B = repmat('%',1,length(A));
C = sprintf('%s\n%s\n%s\n',B,A,B);

%
for i = 1:length(nGrp)
    % determines the gap sizes
    [nA1,nB1] = deal(3-floor(log10(i)),3-floor(log10(nGrp(i))));
    [nA2,nB2] = deal(6-(floor(log10(i))+nA1),6-(floor(log10(nGrp(i)))+nB1));
    
    % appends the new data to the struct
    D = sprintf('%s%s%i%s%s%s%i%s%s',a,repmat(' ',1,nA1),i,repmat(' ',1,nA2),...
                a,repmat(' ',1,nB1),nGrp(i),repmat(' ',1,nB2),a);
    C = sprintf('%s%s\n',C,D);
end

% prints the summary information to screen
clc
disp(sprintf('%s%s\n',C,B))