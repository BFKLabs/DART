%PRINT_EPS  Prints figures to eps with fonts embedded
%
% Examples:
%   print_eps filename
%   print_eps(filename, fig_handle)
%
% This function saves a figure as an eps file with the fonts embedded (as
% subsets). This is useful for preparing figures for scientific
% publications which require embedded fonts - prepare the figure on screen
% exactly as you want it, then PRINT_EPS and forget!
%
% This function requires that you have both Ghostscript and pdftops (from
% the Xpdf package) installed on your system and that the executable
% binaries are on your system's path. You can download these from the
% following places:
% Ghostscript: http://www.ghostscript.com
% Xpdf: http://www.foolabs.com/xpdf
%
%IN:
%   filename - string containing the name (optionally including full or
%              relative path) of the file the figure is to be saved as. A
%              ".eps" extension is added if not there already. If a path is
%              not specified, the figure is saved in the current directory.
%   fig_handle - The handle of the figure to be saved. Default: current
%                figure.
%
% Copyright (C) Oliver Woodford 2008

% The idea of using ghostscript is inspired by Peder Axensten's SAVEFIG
% (fex id: 10889) which is itself inspired by EPS2PDF (fex id: 5782).
% The idea for using pdftops came from the MATLAB newsgroup (id: 168171).
% The idea of editing the EPS file to change line styles comes from Jiro
% Doke's FIXPSLINESTYLE (fex id: 17928)
% The idea of changing dash length with line width came from comments on
% fex id: 5743, but the implementation is mine :)

% $Id: print_eps.m,v 1.16 2009/02/12 14:32:25 ojw Exp $

function print_eps(name, fig)
if nargin < 2
    fig = gcf;
end
% Set paper size
set(fig, 'PaperPositionMode', 'auto');
% Print to temporary eps file
tmp_nam = tempname;
print(fig, '-depsc2', '-painters', '-r864', [tmp_nam '.eps']);
% Fix the line styles
fix_lines([tmp_nam '.eps']);

%


% Construct the command string for ghostscript. This assumes that the
% ghostscript binary is on your path - you can also give the complete path,
% e.g. cmd = '"C:\Program Files\gs\gs8.63\bin\gswin32c.exe"';
cmd = sprintf('"%s"',detProgramFilePath('gs'));
cmd = [cmd ' -q -dNOPAUSE -dBATCH -dEPSCrop -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="' tmp_nam '.pdf" -f "' tmp_nam '.eps"'];
% Convert to pdf, embedding fonts and compressing images
result = system(cmd);
% Delete the temporary eps file
delete([tmp_nam '.eps']);
% Exit now if unsuccessful in creating pdf
if result
    return
end
% Construct the filename
if numel(name) < 5 || ~strcmpi(name(end-3:end), '.eps')
    name = [name '.eps']; % Add the missing extension
end

% Construct the command string for pdftops. This assumes that the
% pdftops binary is on your path - you can also give the complete path,
cmd = sprintf('"%s"',detProgramFilePath('Xpdf'));
cmd = [cmd 'pdftops -q -paper match -pagecrop -eps -level2 ' tmp_nam '.pdf "' name '"'];
% Convert the pdf back to eps
system(cmd);
% Delete the temporary pdf file
delete([tmp_nam '.pdf']);
% Fix the DSC error created by pdftops
fid = fopen(name, 'r+');
if fid == -1
    % Cannot open the file
    return
end
fgetl(fid); % Get the first line
str = fgetl(fid); % Get the second line
if strcmp(str(1:min(13, end)), '% Produced by')
    fseek(fid, -numel(str)-1, 'cof');
    fwrite(fid, '%'); % Turn ' ' into '%'
end
fclose(fid);
return

function fix_lines(fname)
% Improve the style of lines used and set grid lines to an entirely new
% style using dots, not dashes

% Read in the file
fh = fopen(fname, 'rt');
fstrm = char(fread(fh)');
fclose(fh);

% Make sure all line width commands come before the line style definitions,
% so that dash lengths can be based on the correct widths
% Find all line style sections
ind = [regexp(fstrm, '[\n\r]SO[\n\r]'),... % This needs to be here even though it doesn't have dots/dashes!
       regexp(fstrm, '[\n\r]DO[\n\r]'),...
       regexp(fstrm, '[\n\r]DA[\n\r]'),...
       regexp(fstrm, '[\n\r]DD[\n\r]')];
ind = sort(ind);
% Find line width commands
[ind2 ind3] = regexp(fstrm, '[\n\r]\d* w[\n\r]', 'start', 'end');
% Go through each line style section and swap with any line width commands
% near by
b = 1;
m = numel(ind);
n = numel(ind2);
for a = 1:m
    % Go forwards width commands until we pass the current line style
    while b <= n && ind2(b) < ind(a)
        b = b + 1;
    end
    if b > n
        % No more width commands
        break;
    end
    % Check we haven't gone past another line style (including SO!)
    if a < m && ind2(b) > ind(a+1)
        continue;
    end
    % Are the commands close enough to be confident we can swap them?
    if (ind2(b) - ind(a)) > 8
        continue;
    end
    % Move the line style command below the line width command
    fstrm(ind(a)+1:ind3(b)) = [fstrm(ind(a)+4:ind3(b)) fstrm(ind(a)+1:ind(a)+3)];
    b = b + 1;
end

% Find any grid line definitions and change to GR format
% Find the DO sections again as they may have moved
ind = int32(regexp(fstrm, '[\n\r]DO[\n\r]'));
if ~isempty(ind)
    % Find all occurrences of what are believed to be axes and grid lines
    ind2 = int32(regexp(fstrm, '[\n\r] *\d* *\d* *mt *\d* *\d* *L[\n\r]'));
    if ~isempty(ind2)
        % Now see which DO sections come just before axes and grid lines
        ind2 = repmat(ind2', [1 numel(ind)]) - repmat(ind, [numel(ind2) 1]);
        ind2 = any(ind2 > 0 & ind2 < 12); % 12 chars seems about right
        ind = ind(ind2);
        % Change any regions we believe to be grid lines to GR
        fstrm(ind+1) = 'G';
        fstrm(ind+2) = 'R';
    end
end

% Isolate line style definition section
first_sec = findstr(fstrm, '% line types:');
[second_sec remaining] = strtok(fstrm(first_sec+1:end), '/');
[dummy remaining] = strtok(remaining, '%');

% Define the new styles, including the new GR format
% Dot and dash lengths have two parts: a constant amount plus a line width
% variable amount. The constant amount comes after dpi2point, and the
% variable amount comes after currentlinewidth. If you want to change
% dot/dash lengths for a one particular line style only, edit the numbers
% in the /DO (dotted lines), /DA (dashed lines), /DD (dot dash lines) and
% /GR (grid lines) lines for the style you want to change.
new_style = {'/dom { dpi2point 1 currentlinewidth 0.08 mul add mul mul } bdef',... % Dot length macro based on line width
             '/dam { dpi2point 2 currentlinewidth 0.04 mul add mul mul } bdef',... % Dash length macro based on line width
             '/SO { [] 0 setdash 0 setlinecap } bdef',... % Solid lines
             '/DO { [1 dom 1.2 dom] 0 setdash 0 setlinecap } bdef',... % Dotted lines
             '/DA { [4 dam 1.5 dam] 0 setdash 0 setlinecap } bdef',... % Dashed lines
             '/DD { [1 dom 1.2 dom 4 dam 1.2 dom] 0 setdash 0 setlinecap } bdef',... % Dot dash lines
             '/GR { [0 dpi2point mul 4 dpi2point mul] 0 setdash 1 setlinecap } bdef'}; % Grid lines - dot spacing remains constant
new_style = sprintf('%s\r', new_style{:});

% Save the file with the section replaced
fh = fopen(fname, 'wt');
fprintf(fh, '%s%s%s%s', fstrm(1:first_sec), second_sec, new_style, remaining);
fclose(fh);
return
