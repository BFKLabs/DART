function [iGrp,varargout] = getGroupIndex(Im,varargin)

a = char(39);

%
pstr = [a,'PixelIdxList',a];
if (~isempty(varargin))
    for i = 1:length(varargin)
        pstr = [pstr,sprintf(',%s%s%s',a,varargin{i},a)];
    end
end

%
fstr = sprintf('regionprops(bwlabel(Im),%s);',pstr);
s = eval(fstr);

%
iGrp = {};
[iGrp{1:length(s),1}] = deal(s.PixelIdxList);

%
for i = 1:(nargout-1)
    a = {};
    fstr = sprintf('deal(s.%s);',varargin{i});
    
    [a{1:length(s),1}] = eval(fstr);
    a = cell2mat(a);
    varargout{i} = a;
end