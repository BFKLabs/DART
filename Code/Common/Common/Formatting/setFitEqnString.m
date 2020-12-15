% --- 
function [fitStr,fitPara,ok] = setFitEqnString(eqStr)

% initialisations
[fitPara,fitStr] = deal(struct('pStr',[],'fStr',[]),[]);
[A,ok] = deal(eqStr,true);

% removes all functions (exp, sin, cos etc) from the string
strF = regexp(eqStr,'[^a-zA-Z]','split'); 
strF = unique(strF(~cellfun(@isempty,strF)));

% determines all the function strings in the object
indF0 = cellfun(@(x)(regexp(eqStr,x,'start')),strF,'un',0);
indFF = cellfun(@(x)(regexp(eqStr,x,'end')),strF,'un',0);
ii = cellfun(@(x)(x < length(eqStr)),indFF,'un',0);

% if there are functions in the string, then remove them
if (~isempty(ii))
    % sets the start/finish indices of the function strings
    indF0 = cell2mat(cellfun(@(x,y)(x(y)),indF0,ii,'un',0));
    indFF = cell2mat(cellfun(@(x,y)(x(y)),indFF,ii,'un',0));

    % removes the function strings from the equation string
    eqStrNx = regexp(eqStr(indFF+1),'\(');
    for i = eqStrNx
        A(indF0(i):indFF(i)) = repmat(' ',length(indF0(i):indFF(i)),1);
    end
end
    
% sets the indices of the sub-scripted parameters 
indS0 = num2cell(regexp(A,'\w\_[a-zA-Z0-9]','start'));
if (~isempty(indS0))
    % if there are sub-script parameter then return their indices
    indSF = num2cell(regexp(A,'\w\_[a-zA-Z0-9]','end'));
    indS = cell2mat(cellfun(@(x,y)(x:y),indS0,indSF,'un',0));
else
    % otherwise, set an empty array
    indS = [];
end
    
% removes from the string all characters that aren't sub-scripted
% parameters or word character strings
jj = false(length(A),1);
jj([indS,regexp(A,'[a-zA-Z0-9\\]')]) = true;
iGrp = getGroupIndex(jj);

% retrieves the remaining parameter strings
isLVar = cellfun(@(x)(strcmp(eqStr(x(1)),'\')),iGrp);
isX = cellfun(@(x)(strcmp(eqStr(x),'x') | strcmp(eqStr(x),'X')),iGrp);
pStr = cellfun(@(x)(eqStr(x)),iGrp,'un',0);
    
% determines the latex variables from the parameter strings
if (any(isLVar))
    % determines if the parameter strings are connected to any other
    % strings (which means the parameter is combined)
    for i = find(isLVar)'                
        if (i ~= length(iGrp))
            % if the latex parameter is connected to another parameter,
            % then join the two groups (removes the joining group)
            if ((iGrp{i+1}(1) - iGrp{i}(end)) == 2)
                iGrp{i} = (iGrp{i}(1):iGrp{i+1}(end))';
                pStr{i} = sprintf('%s%s',pStr{i}(2:end),pStr{i+1});
                [pStr{i+1},iGrp{i+1},isX(i+1)] = deal([],[],true);
            end
        end
    end
end

% removes special values and numerals from the parameter list
isX(cellfun(@(x)(strcmp(x,'\pi')),pStr)) = true;
isX(cellfun(@(x)(~isnan(str2double(x))),pStr)) = true;

% determines it there are duplications of parameters
if (length(pStr(~(isX))) ~= length(unique(pStr(~(isX)))))
    % if so, then exit with an error
    qStr = sprintf(['There are duplication of parameters in the ',...
                    'equation string\n\nDo you wish to continue anyway?']);
    uChoice = questdlg(qStr,'Duplicate Equation Parameters','Yes','No','Yes');
    if (~strcmp(uChoice,'Yes'))
        ok = false; return
    end
end

% removes the parameters that are the dependent variables ('x' or 'X')    
[pStr,iGrp] = deal(pStr(~isX),iGrp(~isX));    
pStr0 = cellfun(@(x)(x(regexp(x,'[a-zA-Z0-9]'))),pStr,'un',0);
[pStr,b,ind] = unique(pStr0);
c = b(ind);

% reduces the equation string by the new parameters
fitStr = eqStr;
for i = length(pStr0):-1:1
    strPr = fitStr(1:(iGrp{i}(1)-1));
    strNx = fitStr((iGrp{i}(end)+1):end);
    fitStr = sprintf('%s%s%s',strPr,char(64+c(i)),strNx);
end

% sets the final fitting parameter strings
[d,ii] = sort(b);
[fitPara.pStr,fitPara.fStr] = deal(pStr(ii),num2cell(char(64+d)));
