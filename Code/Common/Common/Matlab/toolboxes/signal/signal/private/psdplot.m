function [hLine, xscale] = psdplot(Pxx, F, rbw, esttype)
%PSDPLOT Helper function for plotting power and psd estimates.

%   Copyright 2013 The MathWorks, Inc.

hAxes = newplot;
  
[F, xscale, xunits] = engunits(F);  

xlbl = getfreqlbl([xunits 'Hz']);
xlabel(hAxes, xlbl);

if strcmp(esttype,'power')
  H = 10*log10(rbw*Pxx);
  ylbl = getString(message('signal:dspdata:dspdata:PowerdB'));
else %'psd'
  H = 10*log10(Pxx);
  ylbl = getString(message('signal:dspdata:dspdata:PowerfrequencydBHz'));
end

ylabel(hAxes, ylbl);

hLine = line(F, H, 'Parent', hAxes);
set(hAxes, 'XLim', [min(F) max(F)]);

% Ensure axes limits are properly cached for zoom/unzoom
resetplotview(hAxes,'SaveCurrentView');  

initdistgrid(hAxes);
uistack(hLine,'top');