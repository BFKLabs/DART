% --- calculates the histogram matched image stack
function IHM = calcHistMatchStack(I,IRef)

IHM = cellfun(@(x)(double(imhistmatch...
    (uint8(x),IRef,'method','uniform'))),I,'un',0);

