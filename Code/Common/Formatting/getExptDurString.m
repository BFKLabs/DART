% --- converts the duration vector to a string
function tDurS = getExptDurString(tDur)

% converts the duration (in seconds) to the duration string
s = seconds(tDur); 
s.Format = 'dd:hh:mm:ss';
tDurS = char(s);