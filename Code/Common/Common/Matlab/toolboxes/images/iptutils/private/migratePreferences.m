function migratePreferences
% Migrate settings from old preferences api to new settings api

%   Copyright 2011 The MathWorks, Inc.

pref_struct = getpref('ImageProcessing');

s = Settings;
if ~isempty(pref_struct)
    
    pref = 'ImshowInitialMagnification';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        if isnumeric(value)
            new_style = 'numeric';
            new_value = value;
        else
            new_style = value;
            new_value = 100;
        end
        s.images.imshow.set('InitialMagnificationStyle',new_style,'user');
        s.images.imshow.set('InitialMagnification',new_value,'user');
    end
    
    pref = 'ImshowAxesVisible';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        new_value = strcmp(value,'on');
        s.images.imshow.set('ShowAxes',new_value,'user');
    end
    
    pref = 'ImshowBorder';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        s.images.imshow.set('BorderStyle',value,'user');
    end
    
    pref = 'ImtoolInitialMagnification';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        if isnumeric(value)
            s.images.imtool.set('InitialMagnificationStyle','numeric','user');
            s.images.imtool.set('InitialMagnification',value,'user');
        else
            s.images.imtool.set('InitialMagnificationStyle',value,'user');
            s.images.imtool.set('InitialMagnification',100,'user');
        end
    end
    
    pref = 'ImtoolStartWithOverview';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        s.images.imtool.set('OpenOverview',value,'user');
    end
    
    pref = 'UseIPPL';
    if isfield(pref_struct,pref)
        value = pref_struct.(pref);
        s.images.set('UseIPPL',value,'user');
    end
    
end
        
% set migrated flag
s.images.set('PreferencesMigrated',true,'user');
