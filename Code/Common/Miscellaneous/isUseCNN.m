function useCNN = isUseCNN(iData,iMov)

% determines if the video is run by HT controller and the deep learning
% toolbox is available
useCNN = isHTController(iData) && detectToolbox('Deep Learning Toolbox');

% if the region data struct is given, then determine if the model is set
% (this form is used when checking a loaded solution file)
if useCNN && exist('iMov','var')
    useCNN = ~isempty(iMov.pCNN) && ~isempty(iMov.pCNN.pNet);
end