% --- resets the plot axis positions so that they are equal in size
function resetAxisPos(hAx)        
        
% resets the axis positions (so that they are equal)
axPos1 = get(hAx(1),'position');
axPos2 = get(hAx(2),'position');
axPosNw = [axPos1(1:2) (axPos2(3)-(axPos1(1)-axPos2(1))) axPos1(4)];
cellfun(@(x)(set(x,'position',axPosNw)),num2cell(hAx))        

