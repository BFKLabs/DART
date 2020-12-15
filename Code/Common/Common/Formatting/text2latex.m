% --- converts a text string to latex
function [latexStr,ok] = text2latex(eqStr,fcnStr)

% ------------------------------------------- %
% --- INITIALISATIONS & MEMORY ALLOCATION --- %
% ------------------------------------------- %

% initialisations
[latexStr,ok] = deal([],true);

% % removes all the white-space characters and 
% eqStr = eqStr(regexp(eqStr,'\S'));

% removes errors from the string
ii = strfind(eqStr,'exp^');
if (~isempty(ii))
    for i = ii; eqStr = [eqStr(1:(i+2)),eqStr((i+4):end)]; end
end

% converts string to integer form
eqStrN = uint8(eqStr);

% ----------------------------- %
% --- EQUATION STRING CHECK --- %
% ----------------------------- %

% checks the equation to determine if it is valid
[eStr,Border] = checkEqnString(eqStrN);
if (~isempty(eStr))
    % if there was an error, then output an error to screen and exit
    waitfor(errordlg(sprintf('Error! %s',eStr),'Text String Error','modal'))
    ok = false;
    return
end

% ----------------------------- %
% --- LATEX STRING CREATION --- %
% ----------------------------- %

% splits the strings up by their brackets
if (~isempty(Border))
    % splits the strings by their brackets    
    eqStrSP = setBracketCells(eqStr,Border);    
else
    % otherwise, set the entire string into an array
    eqStrSP = {eqStr};
end

% re-orders the cell of strings to account for super/sub-script terms
eqStrSP = setExponentStrings(eqStrSP,'^');
eqStrSP = setExponentStrings(eqStrSP,'_');
eqStrSP = recombineCellStrings(eqStrSP);

% sets all the divisor strings
eqStrSP = setDivideString(eqStrSP);

% sets all the other math operator strings
eqStrSP = setMathStrings(eqStrSP,'*','');

% sets the final latex string
latexStr = sprintf('$%s%s$',fcnStr,cell2mat(eqStrSP'));
latexStr = latexStr(regexp(latexStr,'[^\"]'));

% --- recombines the cell strings into a cell array of strings
function eqStrSP = recombineCellStrings(eqStrSP)

% loops through all of the cell strings removing any sub-cell arrays
for i = 1:length(eqStrSP)
    % if the current cell is a cell itself, check the sub-cell arrays and
    % combine the cell into a final array
    if (iscell(eqStrSP{i}))
        eqStrSP{i} = recombineCellStrings(eqStrSP{i});
        eqStrSP{i} = cell2mat(eqStrSP{i}');
    end
end
    
% -------------------------------- %
% --- ERROR CHECKING FUNCTIONS --- %
% -------------------------------- %

% --- checks the equation string to determine if it is valid
function [eStr,Border] = checkEqnString(eqStrN)

% initialisations
[eStr,Border] = deal([]);
nonStr = uint8('{}!@#$%&[]~<>:;?"''');

% check to see if ther are any invalid characters in the equation string
ii = cellfun(@(x)(any(eqStrN == x)),num2cell(nonStr,1));
if (any(ii))
    % if so, set the error string with the offending characters
    eStr = sprintf('Following invalid character(s) are used in input string:\n');
    for i = find(ii)
        eStr = sprintf('%s\n => %s',eStr,char(nonStr(i)));
    end
elseif  (isempty(regexp(char(eqStrN),'[xX]\W', 'once')))
    % if not any dependent variable characters, then exit
    eStr = 'Dependent variable "x" missing from equation.';
else
    % determines all the open/closed brackets
    [indOB,indCB] = detBracketIndices(eqStrN);
        
    % check to see if the open and closed brackets match
    if (length(indOB) ~= length(indCB))
        % if not, set an error string
        eStr = 'Number of open/closed brackets do not match.';
    elseif (~isempty(indOB))
        % check to see the open/close brackers are in correct order (i.e.,
        % all closed brackets match up with the open brackets)
        Border = detBracketOrder(indOB,indCB);        
        if (any(Border(:,2) < 0))
            % otherwise, output the error
            eStr = 'The open/closed brackets do not match correctly.';
        end
    end        
end

% ---------------------------------- %
% --- STRING SPLITTING FUNCTIONS --- %
% ---------------------------------- %

% --- splits a string into cell arrays via its brackets 
function eqStrSP = setBracketCells(eqStr,Border)

% determines the indices of the open/closed brackets
if (nargin == 1)
    % determines all the open/closed brackets
    [indOB,indCB] = detBracketIndices(uint8(eqStr(2:end-1)));    
    if (isempty(indOB))
        eqStrSP = eqStr; return
    else
        Border = detBracketOrder(indOB,indCB);
        Border(:,1) = Border(:,1) + 1;
    end
end
    
% sets the indices of the open brackets
indCB = Border(Border(:,2) == 0,1);
[jOfs,nStr] = deal(0,length(eqStr));

% determines the closed bracket index for the lowest order (order 1)
indOB = zeros(length(indCB),1);
for i = 1:length(indCB)
    % sets the index of the next open bracket and find where it is located
    % in the overall bracket sum array
    iOfs = find(Border(:,1) == indCB(i));

    % sets the level of the open bracket, and determine which index
    % corresponds to the closing bracket (associated with the open bracket)    
    indOB(i) = Border(find(Border((jOfs+1):(iOfs-1),2) == 1,1,'first')+jOfs,1);    
    jOfs = find(Border(:,1) == indCB(i));
end

% sets the indices of the string seperations 
indSP = cellfun(@(x)(x(1):x(2)),num2cell([indOB,indCB],2),'un',0);
eqStrSP = cellfun(@(x)(eqStr(x)),indSP,'un',0);

% if there are higher orders, then split the cells even more
if (max(Border(:,2)) > 1)
    for i = 1:length(eqStrSP)        
        eqStrSP{i} = setBracketCells(eqStrSP{i});
    end
end

% determines the string portions not included in the brackets
N = length(indSP);
if (indOB(1) ~= 1); indSP = [indSP;{1:(indOB(1)-1)}]; end
for i = 1:(length(indOB)-1); indSP = [indSP;{(indCB(i)+1):(indOB(i+1)-1)}]; end
if (indCB(end) ~= nStr); indSP = [indSP;{(indCB(end)+1):nStr}]; end

% adds the other string portions to the cell array
eqStrSP = [eqStrSP;cellfun(@(x)(eqStr(x)),indSP((N+1):end),'un',0)];

% sorts the separations in ascending order
[~,jj] = sort(cellfun(@(x)(x(1)),indSP));
eqStrSP = eqStrSP(jj);

% --- reorders string cell arrays to account for exponential terms 
function eqStrSP = setExponentStrings(eqStrSP,sStr)

% loops through each of the cells converting the exponential components
for i = 1:length(eqStrSP)
    if (iscell(eqStrSP{i}))
        % if the current cell is a cell array, search recursively
        eqStrSP{i} = setExponentStrings(eqStrSP{i},sStr);
    else
        % check for any instances of the exponential function
        if (strcmp(sStr,'^'))
            ii = strfind(lower(eqStrSP{i}),'exp');
            if (~isempty(ii))        
                % if it exists, and occupies the end of the cell with the next
                % cell being a bracket, then combine the exponential with the
                % next cell while removing it from the current
                if (i ~= length(eqStrSP)) 
                    if (ii == length(eqStrSP{i})-2)
                        if (iscell(eqStrSP{i+1}))
                            eqStrSP{i} = eqStrSP{i}(1:(ii-1));
                            eqStrSP{i+1}{1} = sprintf('e^{%s',eqStrSP{i+1}{1}(2:end));                                                    
                            eqStrSP{i+1}{end} = sprintf('%s}',eqStrSP{i+1}{end}(1:end-1));
                        else
                            eqStrSP{i} = eqStrSP{i}(1:(ii-1));
                            eqStrSP{i+1} = sprintf('e^{%s}',eqStrSP{i+1}(2:end-1));                        
                        end
                    end                    
                end
            end
        end
        
        % check for any instance of exponents
        jj = strfind(eqStrSP{i},sStr);
        if (~isempty(jj))
            for j = reshape(jj(end:-1:1),1,length(jj))            
                if (i ~= length(eqStrSP))
                    % if the searcg string is at the end of the comparison
                    % string, and the next cell is a bracket, then combine the
                    % search string with the bracket term
                    if ((j == length(eqStrSP{i})) && strcmp(eqStrSP{i+1}(1),'('))
                        eqStrSP{i} = eqStrSP{i}(1:(j-1));
                        eqStrSP{i+1} = sprintf('"%s{%s}"',sStr,eqStrSP{i+1}(2:end-1));                
                    else
                        if (~strcmp(eqStrSP{i}(j+1),'{'))
                            %
                            opInd = regexp(eqStrSP{i}((j+1):end),'[*+-/\}\)\"]');
                            if (isempty(opInd))
                                % sets the new equation string
                                eqStrSP{i} = sprintf('%s"%s{%s}"',...
                                            eqStrSP{i}(1:(j-1)),sStr,...
                                            eqStrSP{i}((j+1):end));
                            else
                                % resets the string parts to include the seperator
                                k = opInd(1)+j;
                                eqStrSP{i} = sprintf('%s"%s{%s}"%s',...
                                            eqStrSP{i}(1:(j-1)),sStr,...
                                            eqStrSP{i}((j+1):(k-1)),eqStrSP{i}(k:end));
                            end                        
                        end                                               
                    end
                end
            end                
        end
    end
end

% --- reorders string cell arrays to account for division terms 
function eqStrSP = setDivideString(eqStrSP)

% loops through each of the cells converting the exponential components
for i = 1:length(eqStrSP)
    if (iscell(eqStrSP{i}))
        % if the current cell is a cell array, search recursively
        eqStrSP{i} = setDivideString(eqStrSP{i});
    else
        %
        eqStrSPNw = deal(eqStrSP{i});
        ii = regexp(eqStrSPNw,'[\"]');
        for j = 1:(length(ii)/2)
            eqStrSPNw(ii(2*j-1):ii(2*j)) = '?';
        end
        
        % determines the location of the divisor string in current string
        [jj,k] = deal(strfind(eqStrSPNw,'/'),i);
        if (~isempty(jj))
            for j = reshape(jj(end:-1:1),1,length(jj))            
                % sets the numerator string                
                if (j == 1)
                    % if the 
                    PrStr = '';
                    if (i > 1)
                        % if not start, then set numerator to previous cell
                        NStr = eqStrSP{i-1};
                        eqStrSP{i-1} = '';
                    else
                        % if first cell, then set an empty numerator
                        NStr = '';
                    end
                else
                    % otherwise, previous division cessation string
                    [a,b] = deal(eqStrSPNw(1:(j-1)),eqStrSP{i}(1:(j-1)));
                    kk = regexp(a,'[\=\+\-\(\{]');
                    
%                     % if there is an open bracket, but no closed bracket,
%                     % within the search, then look for the open bracket as
%                     % the delimiter instead
%                     if (~isempty(strfind(a(kk(end):end),'{')) && ...
%                                     isempty(strfind(a(kk(end):end),'}')))
%                         kk = regexp(a,'[\{]');                        
%                     end
                                        
                    % sets the previous and numerator strings
                    if (isempty(kk))
                        [PrStr,NStr] = deal([],b);
                    else
                        [PrStr,NStr] = deal(b(1:kk(end)),b((kk(end)+1):end));                    
                    end
                end
                
                % sets the denominator string
                if (j == length(eqStrSP{i}))
                    % determines where the candidate string is in relation
                    % to the entire string length
                    NxStr = '';
                    if (i < length(eqStrSP))
                        % if not the end, then set denominator to next cell
                        [DStr,eqStrSP{i},k] = deal(eqStrSP{i+1},'',i+1);
                    else
                        % if the last cell, then set an empty denominator
                        DStr = '';
                    end
                else
                    % otherwise, next division cessation string
                    [a,b] = deal(eqStrSPNw((j+1):end),eqStrSP{i}((j+1):end));
                    kk = regexp(a,'[\+\-\}\)]');
                    
                    % sets the next and denominator strings
                    if (isempty(kk))
                        [NxStr,DStr] = deal([],b);
                    else
                        [NxStr,DStr] = deal(b(kk(1):end),b(1:(kk(1)-1)));                    
                    end              
                end
                
%                 % removes any cells from the strings
%                 if (iscell(DStr)); DStr = cell2mat(recombineCellStrings(DStr)'); end
%                 if (iscell(NStr)); NStr = cell2mat(recombineCellStrings(NStr)'); end
%                 
                % resets the entire string
                eqStrSP{k} = sprintf('%s%s{%s}{%s}%s',PrStr,'\frac',NStr,DStr,NxStr);
            end
        end
    end
end
        
% --- 
function eqStrSP = setMathStrings(eqStrSP,sStr,lStr)

% replaces all the instances of sStr with lStr
for i = 1:length(eqStrSP)
    % determines all the instances of the search string, sStr
    jj = strfind(eqStrSP{i},sStr);
    for j = reshape(jj(end:-1:1),1,length(jj))   
        %
        eqStrSP{i} = sprintf('%s%s%s',eqStrSP{i}(1:(j-1)),...
                                            lStr,eqStrSP{i}((j+1):end));
    end
end

% ------------------------------- %
% --- MISCELLANEOUS FUNCTIONS --- %
% ------------------------------- %

% --- determines the indices of the open/closed brackets
function [indOB,indCB] = detBracketIndices(eqStrN)

[indOB,indCB] = deal(find(eqStrN == uint8('(')),find(eqStrN == uint8(')')));

% --- determines the bracket orders of the open/closed brackets
function Border = detBracketOrder(indOB,indCB)

% sorts the open/closed bracket indices in ascending order
[a,b] = deal([indOB' indCB'],repmat([1 -1],length(indOB),1));
[c,ii] = sort(a(:),'ascend'); 

% calculates the sum of the open/closed bracket indices (i.e., their order)
Border = [c,reshape(cumsum(b(ii)),length(ii),1)];        