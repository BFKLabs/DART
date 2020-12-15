% --- determines if the experiment had any random stimuli parameters
function isRand = hasRand(iStim)

% determines if any of the parameter fields were random
isRand = any(field2cell(getStructFields(iStim.iPara{1}(1),[],1),'isRand',1));