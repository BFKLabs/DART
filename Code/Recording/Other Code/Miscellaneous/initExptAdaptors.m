% --- initialises the experimental adaptor objects --- %
function [objIMAQ,objDACInfo,exptType,iStim] = ...
                            initExptAdaptors(handles,iStim,isInit)

if isInit
    [objIMAQ,objDACInfo,exptType] = AdaptorInfo(handles.figFlyRecord);                            
else
    [objIMAQ,objDACInfo,exptType] = AdaptorInfo(handles.figFlyRecord,2);                            
end
                        
% prompts the user to set the adaptor information
if ~isempty(objDACInfo)              
    % sets up the parameter fields (if IMAQonly)
    iStim.nDACObj = length(objDACInfo.vSelDAC);
    if iStim.nDACObj > 0
        % sets the DAC channel IDs and string names
        iStim = setChannelID(objDACInfo,iStim);
                
        % allocates memory for sub-structs
        iStim.oPara = repmat(iStim.oPara,iStim.nDACObj,1);        
        
        % limits the voltages on the custom serial objects
        isSTM = find(cellfun(@(x)(strcmp(x,...
                'STMicroelectronics STLink Virtual COM Port')),...
                objDACInfo.BoardNames));
        for i = reshape(isSTM,1,length(isSTM))
            iStim.oPara(i).vMin = 2.0;
            iStim.oPara(i).vMax = 3.5;
        end
    else
        % otherwise, set an empty array for the channel names
        iStim.oPara = struct('vMin',0.5,'vMax',2.5,'sRate',50);
    end    
end    
