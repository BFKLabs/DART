% --- retrieves the formatting parameter struct for the analysis figures
function pF = retFormatStruct(pF,sz)

% retrieves the subplot font sizes (give the number of subplots)
[tSz,lblSz,axSz] = getSubplotFontSizes(max(sz));
fldNames = fieldnames(pF);

% updates the font sizes for all the fields
for i = 1:length(fldNames)
    % sets the font size dependent on the field name
    switch (fldNames{i})
        case ('Title')
            fSizeNw = tSz;
        case ('Axis')
            fSizeNw = axSz;
        case ('Legend')
            fSizeNw = axSz - 2;            
        otherwise
            fSizeNw = lblSz;
    end
    
    % resets the sub-struct font sizes
    pp = eval(sprintf('pF.%s;',fldNames{i}));
    for j = 1:length(pp)
        pp(j).Font.FontSize = fSizeNw;
    end

    % updates the parameter struct
    if (length(pF) == 1)
        eval(sprintf('pF.%s = pp;',fldNames{i}));
    else
        for j = 1:length(pF)
            eval(sprintf('pF(j).%s = pp;',fldNames{i}));
        end
    end
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- sets the font sizes based on the number of apparatus
function [tSz,lblSz,axSz] = getSubplotFontSizes(szMax)

% sets the font sizes based on the operating system (has differing formats)
if (ispc)
    % font sizes for PC
    switch (szMax)
        case (1)
            [tSz,lblSz,axSz] = deal(30,22,18);
        case (2)
            [tSz,lblSz,axSz] = deal(24,18,14);
        case (3)
            [tSz,lblSz,axSz] = deal(20,16,12);
        case (4)
            [tSz,lblSz,axSz] = deal(18,14,10);
        case (5)
            [tSz,lblSz,axSz] = deal(16,13,11);
        otherwise
            [tSz,lblSz,axSz] = deal(14,12,10);
    end    
else
    % font sizes for Mac
    switch (szMax)
        case (1)
            [tSz,lblSz,axSz] = deal(32,24,20);
        case (2)
            [tSz,lblSz,axSz] = deal(26,20,16);
        case (3)
            [tSz,lblSz,axSz] = deal(20,16,12);
        case (4)
            [tSz,lblSz,axSz] = deal(18,14,10);            
        case (5)
            [tSz,lblSz,axSz] = deal(16,13,11);
        otherwise
            [tSz,lblSz,axSz] = deal(14,12,10);
    end    
end