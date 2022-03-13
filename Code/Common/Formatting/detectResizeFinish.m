% --- determines when a resized figure has finished being resized and
%     returns the final figure size
function sz = detectResizeFinish(hObject)

% keep looping until the size stops changing
sz0 = get(hObject,'Position');
while 1
    % pause of a short amount of time...
    pause(0.25)

    % determines if the figure size has changed
    sz = get(hObject,'Position');
    if isequal(sz,sz0)
        % if not, then exit the loop
        break
    else
        % otherwise, reset the figure size vector
        sz0 = sz;
    end
end