function pTol = getThreshTol(Img,pC,varargin)

%
Img = Img(~isnan(Img));
if (isempty(Img))
    pTol = NaN;
    return
end

%
[f,x] = ecdf(Img(:));
if (nargin == 3)
    jj = x ~= max(x);
    [f,x] = deal(f(jj),x(jj));
    f = f/f(end);
end

%
[PC,F] = meshgrid(pC,f);
[~,imn] = min(abs(F-PC),[],1);
pTol = x(imn);