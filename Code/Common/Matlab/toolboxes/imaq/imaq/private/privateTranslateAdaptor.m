function newAdaptorName = privateTranslateAdaptor(oldAdaptorName)
% PRIVATETRANSLATEADAPTOR Translate adaptor names when adaptors are renamed.
%    newAdaptorName = privateTranslateAdaptor(oldAdaptorName) translates
%    the provided oldAdaptorName into a new adaptor name, newAdaptorName.
%    This is used when an adaptor is renamed to allow backwards
%    compatibility.  It allows the user's code to work without
%    modification.
%
%    This function is meant for internal use only and should not be called
%    directly.
%
%    See also VIDEOINPUT, IMAQHWINFO.

% Copyright 2010 The MathWorks, Inc.
% $ Revision: $ $Date $

origWarnState = warning('backtrace', 'off');
clearWarn = onCleanup(@() warning(origWarnState));
persistent didDalsaWarn;
persistent didIFCWarn;

if isempty(didDalsaWarn)
    didDalsaWarn = false;
    didIFCWarn = false;
end

switch lower(oldAdaptorName)
    case 'coreco'
        info = imaqhwinfo;
        installedAdaptors = info.InstalledAdaptors;
        if any(strcmp('dalsa', installedAdaptors))
            newAdaptorName = 'dalsa';
                        
            if ~didDalsaWarn
                warning(message('imaq:dalsa:renamedAdaptor'));
                didDalsaWarn = true;
            end
            return;
        elseif any(strcmp('dalsaifc', installedAdaptors))
            newAdaptorName = 'dalsaifc';
            
            if ~didIFCWarn
                warning(message('imaq:dalsaifc:renamedAdaptor'));
                didIFCWarn = true;
            end
            return;
        else
            error(message('imaq:coreco:unsupported'));
        end               
    otherwise
        newAdaptorName = oldAdaptorName;
end
        