% --- sets the data values from Ynw into the array, Y
function Y = setPhaseDataField(Y,Ynw,iPh,iExp)

for i = 1:length(Ynw)
    Y{1,i,iExp}(iPh) = Ynw(i);
end