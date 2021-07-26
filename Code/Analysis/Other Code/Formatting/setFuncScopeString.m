function sStr = setFuncScopeString(Type)

sStr = strrep(strjoin(cellfun(@(x)(x(1)),Type,'un',0),'/'),'P','S');