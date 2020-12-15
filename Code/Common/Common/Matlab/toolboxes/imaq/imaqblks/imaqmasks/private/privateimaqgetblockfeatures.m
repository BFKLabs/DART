function [hiddenFeatures, featureTypes] = privateimaqgetblockfeatures
%PRIVATEIMAQGETBLOCKFEATURES Returns user data value for the specified block.
%
%    [HIDDENFEATURES, FEATURETYPES] = PRIVATEIMAQGETBLOCKFEATURES
%    Returns hidden imaqmex features, HIDDENFEATURES, and 
%    types, FEATURETYPES.

%    SS 10-22-11
%    Copyright 2011 The MathWorks, Inc.

% Query IMAQMEX hidden features.
hiddenFeatures = imaqmex('queryfeatures'); 

% Query feature types.
featureNames = fields(hiddenFeatures);
featureTypes = int32(zeros(1,length(featureNames)));
for idx=1:length(featureNames)
    featureValue = hiddenFeatures.(featureNames{idx});
    featureTypes(idx) = int32(islogical(featureValue));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%