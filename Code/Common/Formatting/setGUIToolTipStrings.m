% --- sets the tooltip strings for all objects in a GUI, hFig
function setGUIToolTipStrings(hFig)

% initialisations
[tagStr,ttStr] = deal([]);

% -------------------------------------------- %
% --- TOOLTIP STRING/OBJECT INITIALISATION --- %
% -------------------------------------------- %

% sets the tooltip object/string arrays (dependent on the GUI type)
switch get(hFig,'tag')
    % ------------------------- %
    % --- MAIN DART FIGURES --- %
    % ------------------------- %    
    
    case 'figDART'
         % case is the ?? GUI   

    % ------------------------------------- %
    % --- QUANTITATIVE ANALYSIS FIGURES --- %
    % ------------------------------------- %
         
    case 'figFlyAnalysis'
         % case is the ?? GUI   
                 
    case 'figAlterData'
         % case is the ?? GUI   
         
    case 'figAnalysisPara'
         % case is the ?? GUI   
         
    case 'figDataOutput'
         % case is the ?? GUI   
         
    case 'figFuncComp'
         % case is the ?? GUI   
         
    case 'figGlobalPara'
         % case is the ?? GUI   
         
    case 'figStatMet'
         % case is the ?? GUI   
         
    case 'figOutputData'
         % case is the ?? GUI   
         
    case 'figProgDef'
         % case is the ?? GUI   
             
    case 'figSaveFig'
         % case is the ?? GUI   
         
    case 'figSplitPlot'
         % case is the ?? GUI   
         
    case 'figStatTest'
         % case is the ?? GUI   
         
    case 'figUndockPlot'
         % case is the ?? GUI   
         
    % ------------------------------ %
    % --- DATA COMBINING FIGURES --- %
    % ------------------------------ %  
         
    case 'figFlyCombine'
         % case is the ?? GUI   
         
    case 'figMultCombInfo'
         % case is the ?? GUI   
         
    case 'figExptSave'
         % case is the ?? GUI   
         
    case 'figMultiSave'
         % case is the ?? GUI   
         
    % ------------------------------- %
    % --- COMMON FUNCTION FIGURES --- %
    % ------------------------------- %         
         
    case 'figAboutDART'
         % case is the ?? GUI   
         
    case 'figProgDiag'
         % case is the ?? GUI   
         
    case 'figExeUpdate'
         % case is the ?? GUI   
         
    case 'figInstallInfo'
         % case is the ?? GUI   
         
    case 'figSyncSummary'
         % case is the ?? GUI   
         
    case 'figAnalyFunc'
         % case is the ?? GUI   
         
    case 'figConvertVideo'
         % case is the ?? GUI   
         
    case 'figDirTree'
         % case is the ?? GUI   
         
    case 'figDiskSpace'
         % case is the ?? GUI   
         
    case 'figMultiExptInfo'
         % case is the ?? GUI   
         
    case 'figOpenSoln'
         % case is the ?? GUI   
         
    case 'figQuestDlg'
         % case is the ?? GUI   
         
    case 'figSerialConfig'
         % case is the ?? GUI   
         
    case 'figDeviceNames'
         % case is the ?? GUI   
         
    case 'figTrackPara'
         % case is the ?? GUI   
         
    case 'figTrackStats'
         % case is the ?? GUI   
         
    % -------------------------------------- %
    % --- EXPERIMENTAL RECORDING FIGURES --- %
    % -------------------------------------- %         
         
    case 'figFlyRecord'
         % case is the ?? GUI   
         
    case 'figAdaptInfo'
         % case is the ?? GUI   
         
    case 'figCapturePara'
         % case is the ?? GUI   
         
    case 'figCopySignal'
         % case is the ?? GUI   
         
    case 'figDevicePara'
         % case is the ?? GUI   
         
    case 'figExptProg'
         % case is the ?? GUI   
         
    case 'figExptSetup'
         % case is the ?? GUI   
         
    case 'figTestMovie'
         % case is the ?? GUI   
             
    case 'figVideoPara'
         % case is the ?? GUI   
                 
    case 'figVideoROI'
         % case is the ?? GUI   
         
    % ---------------------------- %
    % --- FLY TRACKING FIGURES --- %
    % ---------------------------- %         
         
    case 'figFlyTrack'
         % case is the ?? GUI   
         
    case 'figAnalyOpt'
         % case is the ?? GUI   
         
    case 'figBGPara'
         % case is the ?? GUI   
         
    case 'figCircPara'
         % case is the ?? GUI   
         
    case 'figFlyCount'
         % case is the ?? GUI   
         
    case 'figFlySolnView'
         % case is the ?? GUI   
         
    case 'figGenPara'
         % case is the ?? GUI   
         
    case 'figAnomRegion'
         % case is the ?? GUI   
         
    case 'figRegionSetup'
         % case is the ?? GUI   
         
    case 'figMultiBatch'
         % case is the ?? GUI   
         
    case 'figSampleRate'
         % case is the ?? GUI   
         
    case 'figScaleFactor'
         % case is the ?? GUI   
         
    case 'figBatchProcess'
         % case is the ?? GUI   
         
    case 'figDiagCheck'
         % case is the ?? GUI   
         
    case 'figMetricPara'
         % case is the ?? GUI   
         
    case 'figSplitSubRegion'
         % case is the ?? GUI   
         
    case 'figStartPoint'
         % case is the ?? GUI   
         
    case 'figStimInfo'
         % case is the ?? GUI   
         
    case 'figVidSplit'
         % case is the video splitting GUI       
         
end

% ----------------------------- %
% --- TOOLTIP STRING UPDATE --- %
% ----------------------------- %

% sets the tooltip strings for each of the specified objects
for i = 1:length(tagStr)
    % retrieves the object handle (based on the tag string)
    hObj = findall(hFig,'tag',tagStr{i});
    if ~isempty(hObj)
        % if the object exists, then update the tooltip string
        set(hObj,'TooltipString',ttStr{i});
    end
end