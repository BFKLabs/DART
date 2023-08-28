% --- calculates the histogram matched image stack
function IHM = calcHistMatchStack(I,IRef)

if iscell(I)
    IHM = cellfun(@(x)(double(imhistmatch...
        (uint8(x),IRef,'method','uniform'))),I,'un',0);
else
    IHM = double(imhistmatch(uint8(I),IRef));
end

