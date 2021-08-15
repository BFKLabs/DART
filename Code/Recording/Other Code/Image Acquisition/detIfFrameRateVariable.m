function isVarFPS = detIfFrameRateVariable(objIMAQ)

% intialisations
srcObj = get(objIMAQ,'source');
pFld = {'AcquisitionFrameRateEnable'};
varCameraType = {'Allied Vision 1800 U-501m NIR'};

% determines if camera has a variable frame rate by either:
%  a) any camera name type in the varCameraType array, or
%  b) the 
isVarFPS = any(cellfun(@(x)(isprop(srcObj,x)),pFld)) || ...
           any(strcmp(varCameraType,objIMAQ.Name));