% --- hack function to ensure the table height is correct
function setTableHeader(hObject)

% global variables
global H0T

% exits if newer version of Matlab
if (~verLessThan('matlab','8.4')); return; end

% resets the header height
jTab = findjobj(hObject); 
jHeader = jTab.getColumnHeader;
sz = jHeader.getPreferredSize; 
sz.height = H0T; 

% updates the header with the new height
jHeader.setPreferredSize(sz); 
jHeader.revalidate;
