% --- 
function colN = getSheetColumnStrings(X)

% determines the indices of each column
[cStr,Nmax] = deal(char([32 65:90]),27*26); 

% converts the column indices to base 26
A = num2cell(dec2base(X,26));
AA = cellfun(@(x)(base2dec(x,26)),A);
 
% ensures the correct indices are set for Z
for i = 2:size(AA,2)
    ii = (AA(:,i-1) > 0)&(AA(:,i) == 0);
    [AA(ii,i),AA(ii,i-1)] = deal(26,AA(ii,i-1)-1);
end

% converts the number back into strings
BB = cellfun(@(x)(cStr(x+1)),num2cell(AA),'un',0);
colN = cellfun(@(x)(cell2mat(x)),num2cell(BB,2),'un',0);

%
if (any(X == Nmax)) 
    colN{X == Nmax} = ' ZZ'; 
end