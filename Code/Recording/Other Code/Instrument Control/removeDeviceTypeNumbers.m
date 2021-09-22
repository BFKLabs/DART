function sType = removeDeviceTypeNumbers(sType0)

% splits the string and returns the first cell
sTypeSp = strsplit(sType0);
sType = sTypeSp{1};