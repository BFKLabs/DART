% --- retrieves the java listbox dimensions for the list width
function HWL = getListDimensions(jObjL)

% retrieves the width of the listbox
jList = jObjL.getViewport.getView;
HWL = jList.getFixedCellHeight;