function tData = centreTableData(tData0)

tData = cellfun(@(x)(sprintf(...
            '<html><tr><td align=center width=9999>%s',x)),tData0,'un',0);