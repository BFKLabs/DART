function isDD = isDirectDetect(iMov)

isDD = ~isempty(strfind(iMov.bgP.algoType,'dd-'));