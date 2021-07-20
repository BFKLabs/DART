% --- sets up the table header string
function hdrStrF = createTableHdrString(hdrStr)

% ensures the header string is contained in a cell array
if ~iscell(hdrStr); hdrStr = {hdrStr}; end
      
% sets the final header string
if length(hdrStr) == 1
    % case is there is only one row
    hdrStrF = sprintf('<html><center>%s</center></html>',hdrStr{1});
else
    % case is there is more than one row
    hdrStrF = sprintf('<html><center>%s<br />%s</center></html>',...
                      hdrStr{1},hdrStr{2});
end