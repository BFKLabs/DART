% --- adds the stimuli axes properties
function showStim = addStimAxesPanels(handles,stimP,sPara,T,isInit)

% sets the default input arguments
if ~exist('T0','var'); T0 = 0; end
if ~exist('isInit','var'); isInit = true; end

% parameters
dY = 10;
yStim = 30;
axCol = 0.9*ones(1,3);

% determines if any stimuli information is available
showStim = ~isempty(stimP);

% retrieves the main figure handle
fStr = fieldnames(handles);
iFig = cellfun(@(x)(startsWith(x,'fig')),fStr);
hFig = getStructField(handles,fStr{iFig});

% object handle retrieval
[hAxS,hAxI] = deal(handles.axesStim,handles.axesImg);
[hPS,hPI] = deal(handles.panelStim,handles.panelImg);  

%
xLimI = get(hAxI,'xlim');
Tmlt = xLimI(2)/T(end);
pDel = diff(T([1 end])*Tmlt)*0.001;

% determines if there is any stimuli information
if showStim  
    % turns the axis hold on
    cla(hAxS)
    hold(hAxS,'on');    

    % retrieves the stimuli device/channel names and parameters
    dType = fieldnames(stimP);
    stimPC0 = cellfun(@(x)(getStructField(stimP,x)),dType,'un',0);
    
    % sets the channel names/colours for each device
    chName0 = cellfun(@(x)(fieldnames(x)),stimPC0,'un',0);
    chName = cellfun(@(x,y)(sortChannelNames(x,y)),chName0,dType,'un',0);
    chCol = cellfun(@(x)(getStimColour(x)),chName,'un',0);
    
    % determines which device/channel combination has stimuli information
    hasStim = cellfun(@(x,y)(cellfun(@(z)(~isempty...
                    (getStructField(x,z,'Ts'))),y)),stimPC0,chName,'un',0);
                    
    % sets the device/channel information strings
    dcInfo = cell2cell(cellfun(@(x,y,z,i)...
                      ([repmat({x},sum(i),1),y(i),z(i)]),...
                       dType,chName,chCol,hasStim,'un',0));
    if isempty(dcInfo)
        showStim = false;
    else
        % retrieves the font-sizes
        axSz = detSolnViewFontSizes(handles);        
        
        % retrieves the stimuli data for each channel
        stimPC = cellfun(@(x)(getStructField(stimP,x{1},x{2})),...
                              num2cell(dcInfo,2),'un',0);                     

        % sets the important plotting variables
        [nStim,yStrS0] = deal(size(dcInfo,1),dcInfo(:,2));
        [yLimS,yTickS] = deal([1 nStim] + 0.5*[-1 1],(1:nStim));
        yStrS0(strcmp(yStrS0,'Ch')) = {'All Ch'};

        % sets up the y-axis strings
        sStr = cellfun(@(x)(regexp(x,'\d','match','once')),...
                                        dcInfo(:,1),'un',0);    
        yStrS = cellfun(@(x,y,z)(sprintf('%s (%s%s)',x,y(1),z)),...
                                        yStrS0,dcInfo(:,1),sStr,'un',0);        

        % creates the stimuli plot objects for each stimuli
        for i = 1:nStim
            % retrieves the stimuli information/parameters
            pCol = dcInfo{i,3};
            [Ts,indS] = deal(stimPC{i}.Ts,stimPC{i}.iStim);
            for j = 1:length(indS)
                sTrain = sPara.sTrain(indS(j));
                [xS,yS] = setupTrainSignal(sTrain,T,Ts(j),dcInfo{i,2},i);

                % creates the stimuli patch object      
                TmltP = Tmlt*60;
                cellfun(@(x,y)(createPatchObject(hAxS,x*TmltP,y,pCol)),xS,yS)         
            end

            % plots the separation markers (except for the last stimuli field)
            if i < nStim
                plot(hAxS,T([1 end])*Tmlt-[pDel,0]',(i+0.5)*[1 1],...
                          'k','linewidth',1,'hittest','off')            
            end
        end

        % reshapes the GUI to hide the missing panel
        axH = nStim*yStim;
        set(hAxS,'Units','Pixels')  
        resetObjPos(hAxS,'Height',axH)
        resetObjPos(hPS,'Height',axH+2*dY)
        resetObjPos(hPI,'Bottom',axH+4*dY)

        % removes hold from the axis
        hold(hAxS,'off')
        axis(hAxS,'ij')
        setObjVisibility(hAxS,'on')

        % sets the other axis properties
        set(hAxS,'xlim',T([1 end])*Tmlt-[pDel,0]','ylim',yLimS'-[0.001;0],...
                 'yticklabel',yStrS,'ytick',yTickS);
        if isInit
            % sets the initialisation only properties
            set(hAxS,'fontweight','bold','fontsize',axSz-6,...
                 'TickLength',[0 0],'LineWidth',1.5,'UserData',2,...
                 'Color',axCol,'box','on');            
        end

        % links the 2-axes in the x-direction
        wState = warning('off','all');
        linkaxes([hAxI,hAxS],'x')
        warning(wState);
    end
end

switch get(hFig,'tag')
    case 'figFlySolnView'
        % if no stimuli, then update the figure properties
        if showStim
            % resets the figure height
            pPos = get(hPI,'Position');
            resetObjPos(hFig,'Height',dY+sum(pPos([2,4])))             
            
        else
            % hide the stimuli info axes panel
            setObjVisibility(handles.menuStim,'off')
            setObjVisibility(handles.menuShowStim,'off')


            % reshapes the GUI to hide the missing panel
            setObjVisibility(handles.panelStim,'off')
            pPos = get(hPI,'Position');
            resetObjPos(hFig,'Height',dY-pPos(2),1)
            resetObjPos(hPI,'Bottom',dY)
        end
        
        % sets the axis font units to normalised
        resetObjProps(hAxS,'FontUnits','Normalized')        

    case 'figFlyCombine'
        % retrieves the outer panel positional coordinates
        pPosO = get(handles.panelExptOuter,'Position');  
        resetObjPos(hFig,'Height',pPosO(4)+2*dY);
        resetObjPos(handles.panelExptOuter,'Bottom',dY)
        
        % sets the stimuli axes units to being normalised
        set(hAxS,'Units','Normalized')
        setObjVisibility(hPS,showStim)
        set(hPI,'Units','Pixels')
        
        if showStim
            % retrieves the position of the stimuli plot panel
            pPosS = get(hPS,'Position');
            yPosI = sum(pPosS([2,4]))+dY;
            
            % resets the axes panel dimensions
            resetObjPos(hPS,'Bottom',dY)
            resetObjPos(hPI,'Bottom',yPosI)
            resetObjPos(hPI,'Height',pPosO(4)-(yPosI-dY))
            
        else
            % reshapes the GUI to hide the missing panel            
            resetObjPos(hPI,'Bottom',dY)
            resetObjPos(hPI,'Height',pPosO(4))                  
        end
        
        set(hPI,'Units','Normalized')
                     
end

% --- sorts the channel names (dependent on device type)
function chName = sortChannelNames(chName,dType)

% sorts the channel names based on the device
switch dType
    case 'Opto'
        chNameS = {'Red';'Green';'Blue';'White'};
        [~,iSort] = sort(cellfun(@(x)(find(strcmp(chNameS,x))),chName));
        chName = chName(iSort);
        
%     case 'Motor'
%         if strcmp(chName,'Ch')
%             chName = {'All Ch'};
%         end
        
end

% --- retrieves the stimuli colour (based on the channel name)
function chCol = getStimColour(chName)

% memory allocation
chCol = cell(size(chName));

% sets the channel colour based on the channel name
for i = 1:length(chName)
    switch chName{i}
        case 'Red'
            chCol{i} = 'r';
            
        case 'Green'
            chCol{i} = 'g';
            
        case 'Blue'
            chCol{i} = 'b';
            
        case 'White'
            chCol{i} = 'y';
            
        otherwise
            if strContains(chName,'Ch')
                chCol{i} = 'k';
            else
                chCol{i} = 'm';
            end
    end
end
            
% --- sets up the train signal
function [xS,yS] = setupTrainSignal(sTrain,T,Ts,chName,iLvl)

%
Tmlt = 1/60;
tUnits = 'm';
Tfinal = T(end)*Tmlt;

%
chN = arrayfun(@(x)(x.chName),sTrain.blkInfo,'un',0);
if strcmp(chName,'Ch')
    iMatch = find(strContains(chN,'Ch #'));
else
    iMatch = find(strcmp(chN,chName));
end

%
y0 = (iLvl-0.5);
tOfs0 = min(arrayfun(@(x)(x.sPara.tOfs),sTrain.blkInfo(iMatch)));

%
[xS,yS] = deal(cell(length(iMatch),1));
for i = 1:length(iMatch)
    % sets up the 
    bInfo = sTrain.blkInfo(iMatch(i));
    [sPara,sType] = deal(bInfo.sPara,bInfo.sType);
    
    % calculates the duration/offset time multipliers
    tMltD = getTimeMultiplier(tUnits,sPara.tDurU);
    tMltO = getTimeMultiplier(tUnits,sPara.tOfsU);
    
    % calculates the signal and scales it for the video time range
    [xS0,yS0] = setupStimuliSignal(sPara,sType,0.01);
    xS{i} = xS0*tMltD + (sPara.tOfs-tOfs0)*tMltO + Ts*Tmlt;
    yS{i} = 1-yS0/100 + y0;
    
    % resets the lower limit of the stimuli if < 0
    if xS{i}(1) < 0
        % determines the feasible time points
        ii = xS{i} > 0;
        ySFnw = detExactSignalValue(xS{i},yS{i},0);
        
        % resets the new values so they fit within the video
        xS{i} = [0;0;xS{i}(ii)];
        yS{i} = [(y0+1);ySFnw;yS{i}(ii)];
    end
    
    % resets the upper limit of the stimuli if > T(end)
    if xS{i}(end) > Tfinal
        % determines the feasible time points
        ii = xS{i} < Tfinal;
        if any(ii)
            ySFnw = detExactSignalValue(xS{i},yS{i},Tfinal);
        
            % resets the new values so they fit within the video
            xS{i} = [xS{i}(ii);Tfinal;Tfinal];
            yS{i} = [yS{i}(ii);ySFnw;(y0+1)];
        end
    end
    
    % resets the coordinates arrays for the patch objects
    xS{i} = xS{i}([1:end,1]);
    yS{i} = yS{i}([1:end,1]);
end

% --- creates the stimuli patch object
function createPatchObject(hAx,x,y,c)

patch(hAx,x,y,c,'LineWidth',1,'FaceAlpha',0.5);

% --- 
function ySF = detExactSignalValue(xS,yS,x0)

%
ii = find(xS<x0,1,'last') + (0:1);
ySF = interp1(xS(ii),yS(ii),x0,'linear');
