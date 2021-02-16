% --- sets the statistics fields into the matlab output data file
function Amat = setMatStatsFields(Amat,pStats)

% retrieves the fieldnames from the stats data array
fStr = fieldnames(pStats);

% appends the fields to the overall matlab file
for i = 1:length(fStr)
    eval(sprintf('Amat.p%s = pStats.%s;',fStr{i},fStr{i}));
end