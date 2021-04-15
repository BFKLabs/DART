function Y = combineNumericCells3(Yc)

% array indexing
Yc = Yc(:);
sz = cell2mat(cellfun(@(x)(size(x)),Yc,'un',0));

% memory allocation
Y = NaN([max(sz,[],1),numel(Yc)]);

%
for i = 1:numel(Yc)
    Y(1:sz(i,1),1:sz(i,2),i) = Yc{i};
end