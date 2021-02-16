% --- retrieves the general motor channel names (for nCh channels)
function chName = getMotorChannelNames(nCh,varargin)

if nargin == 1
    chName = arrayfun(@(x)(sprintf('Ch #%i',x)),(nCh:-1:1)','un',0);
else
    chName = arrayfun(@(x)(sprintf('Ch #%i',x)),(1:nCh)','un',0);
end