% --- combines the data for a given group
function YT = combGroupData(Y)

% sets the inactivity values for the current group
Ynw = Y(:)';
Ynw = Ynw(~cellfun('isempty',Ynw));    

% sets all of the experiments into a single array
YT = false(max(cellfun('length',Ynw)),length(Ynw));
for j = 1:length(Ynw)
    Ynw{j}(isnan(Ynw{j})) = false;
    YT(1:length(Ynw{j}),j) = Ynw{j};
end