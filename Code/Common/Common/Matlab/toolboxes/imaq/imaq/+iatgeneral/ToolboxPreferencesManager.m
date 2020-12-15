classdef ToolboxPreferencesManager < handle
    %TOOLBOXPREFERENCESMANAGER This is the class for managing the toolbox
    % preferences.
    
    % Author: MJ
    % Copyright 2010-2011 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'public')
        GetPrefListener = [];
        SetPrefListener = [];
    end
    
    methods(Access = 'private')
        %%The class constructor must be private to prevent it being invoked
        %%outside the class.
        function obj = ToolboxPreferencesManager
            if usejava('jvm') && ~isdeployed
                jPrefPanel = javaMethodEDT('getPrefPanel', 'com.mathworks.toolbox.imaq.ImaqPrefPanel');
                
                getPrefCallback = handle(jPrefPanel.getGetPrefCallback());
                obj.GetPrefListener = ...
                    handle.listener(getPrefCallback, 'delayed', @(src, data)obj.getPrefCalled());
                
                setPrefCallback = handle(jPrefPanel.getSetPrefCallback());
                obj.SetPrefListener = ...
                    handle.listener(setPrefCallback, 'delayed', @(src, data)obj.setPrefCalled(data.JavaEvent));
            end
            
            try
                obj.loadPreferences();
            catch err %#ok<NASGU>
                if usejava('jvm') && ~isdeployed
                    jPrefs = obj.getPrefsFeaturesFromToolbox();
                    obj.setPrefsFeaturesInToolbox(jPrefs);
                end
            end
        end
        
        function prefs = getPrefsFeaturesFromToolbox(obj)  %#ok<MANU>
            prefs = com.mathworks.toolbox.imaq.ImaqPrefStruct();
            prefs.fGigeCommandPacketRetries = imaqmex('feature', '-gigeCommandPacketRetries');
            prefs.fGigeHeartbeatTimeout = imaqmex('feature', '-gigeHeartbeatTimeout');
            prefs.fGigePacketAckTimeout = imaqmex('feature', '-gigePacketAckTimeout');
            prefs.fGigeDisableForceIP = imaqmex('feature', '-gigeDisableForceIP');
            prefs.fMacvideoDiscoveryTimeout = imaqmex('feature', '-macvideoFramegrabDuringDeviceDiscoveryTimeout');
        end
        
        function getPrefCalled(obj) 
            jPrefPanel = javaMethodEDT('getPrefPanel', 'com.mathworks.toolbox.imaq.ImaqPrefPanel');
            jPrefPanel.setPreferences(obj.getPrefsFeaturesFromToolbox());
        end
        
        function mPrefs = convertJavaPrefsToMATLABStruct(obj, jPrefs) %#ok<MANU>
            fNames = fields(jPrefs);
            for ii=1:length(fNames)
                mPrefs.(fNames{ii}) = jPrefs.(fNames{ii});
            end
        end
        
        function jPrefs = convertMATLABStructToJavaPrefs(obj, mStruct) %#ok<MANU>
            jPrefs = com.mathworks.toolbox.imaq.ImaqPrefStruct();
            fNames = fields(jPrefs);
            for ii=1:length(fNames)
                jPrefs.(fNames{ii}) = mStruct.(fNames{ii});
            end
        end
        
        function setPrefCalled(obj, prefs) 
            mPrefs = obj.convertJavaPrefsToMATLABStruct(prefs); %#ok<NASGU>
            save(fullfile(prefdir,'imaqPreferences.mat'), 'mPrefs');
            obj.setPrefsFeaturesInToolbox(prefs);
        end
        
        function setPrefsFeaturesInToolbox(obj, prefs) %#ok<MANU>
            imaqmex('feature', '-gigeCommandPacketRetries', prefs.fGigeCommandPacketRetries);
            imaqmex('feature', '-gigeHeartbeatTimeout', prefs.fGigeHeartbeatTimeout);
            imaqmex('feature', '-gigePacketAckTimeout', prefs.fGigePacketAckTimeout);
            imaqmex('feature', '-gigeDisableForceIP', prefs.fGigeDisableForceIP);
            imaqmex('feature', '-macvideoFramegrabDuringDeviceDiscoveryTimeout', prefs.fMacvideoDiscoveryTimeout);
        end
        
    end
    
    methods (Access = 'public', Static = true)
        function singleObj = getOrResetInstance(reset)
            persistent localStaticObj;
            if (nargin == 1) && (reset == true)
                delete(localStaticObj);
                localStaticObj = [];
                singleObj = [];
            else
                if isempty(localStaticObj) || ~isvalid(localStaticObj)
                    localStaticObj = iatgeneral.ToolboxPreferencesManager;
                end
                singleObj = localStaticObj;
            end
        end
    end
    
    methods (Access = 'public')
        function loadPreferences(obj)
            mPrefs=[];
            load(fullfile(prefdir,'imaqPreferences.mat'));
            obj.setPrefsFeaturesInToolbox(mPrefs);
        end
        
    end
    
end

