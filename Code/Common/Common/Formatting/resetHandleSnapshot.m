% --- resets the object handles properties snapshot --- %
function resetHandleSnapshot(hProp,hGUI)

% resets all the object properties given in hProp
for i = 1:length(hProp)
    % retrieves the data struct array from the properties struct
    dataNw = hProp(i).data;
    
    % sets the object property fields
    for j = 1:size(dataNw,1)
        set(hProp(i).hObj,dataNw{j,1},dataNw{j,2})
    end
end
% 
% % updates the image
% if (nargin == 2)
%     dispImage = getappdata(hGUI,'dispImage');
%     dispImage(guidata(hGUI))
% end