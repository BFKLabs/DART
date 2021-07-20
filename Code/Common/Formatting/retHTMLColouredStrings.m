% --- converts the an HTML colour string, StrCol, into the base string, Str
function Str = retHTMLColouredStrings(StrNw)

% removes the HTML code component of the string
if ~strContains(StrNw,'<')       
    Str = StrNw;
else
    jj = max([strfind(StrNw,'">'),strfind(StrNw,'b>'),strfind(StrNw,'l>')]);    
    Str = StrNw((jj(end)+2):end);
end    