% --- converts the string, Str into an HTML colour string, which is StrCol
function StrNw = setHTMLColourString(StrCol,Str,varargin)

% converts the string array to a cell array
if ~iscell(Str)
    Str = {Str};
end

% converts the string colour array to a cell array
if ~iscell(StrCol)
    StrCol = {StrCol};
end

% ensures the string colours have the same length as the string array
if (length(StrCol) == 1) && (length(Str) > 1)
    StrCol = repmat(Str,length(Str),1);
end

% memory allocation
StrNw = cell(length(Str),1);

% converts the string based on the colour string
for i = 1:length(Str)
    switch (StrCol{i})
        case {'gr','grey','gray'} % colours is grey (invalid)
            StrNw{i} = sprintf('<html><font color="#6E6E6E">%s',Str{i});
        case {'r','red'} % case is red (error)
            StrNw{i} = sprintf('<html><font color="red">%s',Str{i});
        case {'p','purple'} % case is purple (information)
            StrNw{i} = sprintf('<html><font color="#FF00FF">%s',Str{i});
        case {'g','green'} % case is green (ok)
            StrNw{i} = sprintf('<html><font color="green">%s',Str{i});
        case {'o','orange'} % case is orange (warning)
            StrNw{i} = sprintf('<html><font color="#FF8000">%s',Str{i});
        case {'kb','bold'} % case is black (default colour so no need to change)
            StrNw{i} = sprintf('<html><b>%s',Str{i});            
        case {'k','black'} % case is black (default colour so no need to change)
            StrNw{i} = Str{i};
        case {'b','blue'} % case is blue
            StrNw{i} = sprintf('<html><font color="blue">%s',Str{i});            
    end
end
    
if length(Str) == 1 && nargin == 3
    StrNw = StrNw{1};
end