function Yrng = arange(Y,dim)

%
if exist('dim','var')
    Yrng = max(Y,[],dim,'omitnan') - min(Y,[],dim,'omitnan');
else
    Yrng = max(Y,[],'omitnan') - min(Y,[],'omitnan');
end