function runBeep(nRep,tPause)

if ~exist('nRep','var'); nRep = 1; end
if ~exist('tPause','var'); tPause = 1; end

% runs the first beep
beep

% runs the subsequeny beeps
for i = 2:nRep
    pause(tPause);
    beep
end