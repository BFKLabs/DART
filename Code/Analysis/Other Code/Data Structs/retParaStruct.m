% --- retrieves the parameter struct from the data string struct, pStr -- %
function p = retParaStruct(pStr,varargin)

% retrieves the parameter field/values from the data string struct
[fStr,fVal,fType] = field2cell(pStr,{'Para','Value','Type'});
 
% creates an empty struct and add in all the fields
p = struct();
for i = 1:length(fVal)
    switch (fType{i})
        % ------------------------------------ %
        % --- SPECIALITY PARAMETER STRUCTS --- %
        % ------------------------------------ %
        
        case ('Time') % case is the time limit parameter struct
            % sets the time parameter struct
            [pVal,Lim] = deal(fVal{i},pStr(i).Lim);
                        
            % sets the upper limit time
            Tadd = convertTime(12,'hrs','sec');
            tLo = vec2sec(pVal.Lower) + (pVal.Lower(4)*Tadd);            
            tHi = vec2sec(pVal.Upper) + (pVal.Upper(4)*Tadd);
            
            % sets the lower/upper limits for the figure
            p.xLim = [tLo tHi] - Lim(1);      
            
        case ('Subplot') % case is the subplot parameter struct  
            % sets the time parameter struct
            if (fVal{i}.isComb)
                [nRow,nCol] = deal([]);
            else
                [nRow,nCol] = deal(fVal{i}.nRow,fVal{i}.nCol);
            end
            
            % sets the subplot parameter struct fields
            p.Sub = struct('isPlot',fVal{i}.isPlot,'nRow',nRow,...
                           'nCol',nCol,'isComb',fVal{i}.isComb);
            
        case ('Stim') % case is the stimuli response parameter struct
            % sets the stimuli response parameters
            if (isstruct(pStr(i).Lim))
                p.pInd = pStr(i).Lim.appInd;
                if (isfield(pStr(i).Lim,'plotTrace'))
                    p.pT = pStr(i).Lim.plotTrace;            
                    p.pF = pStr(i).Lim.plotFit;
                end
            else
                p.pInd = pStr(i).Lim;
            end
                       
        % ---------------------------------- %
        % --- ORDINARY PARAMETER STRUCTS --- %
        % ---------------------------------- %
        
        case ('Number') % case is a numerical variable
            if (mod(fVal{i},1) == 0)
                % if an integer, set as within the string a integer
                eval(sprintf('p.%s = %i;',fStr{i},fVal{i}))
            else
                % otherwise, set number as a float value
                eval(sprintf('p.%s = %f;',fStr{i},fVal{i}))
            end      
            
        case ('Boolean') % case is a boolean variable            
            eval(sprintf('p.%s = logical(%i);',fStr{i},fVal{i}))            
            
        case ('String') % case is a string variable
            eval(sprintf('p.%s = %s;',fStr{i},fVal{i}))
            
        case ('List') % case is a list variable
            eval(sprintf('p.%s = ''%s'';',fStr{i},fVal{i}{2}{fVal{i}{1}}))           
    end
end

% sets the global parameters (if they are provided)
if (nargin == 2)
    % sets the global parameter struct fieldnames
    gPara = varargin{1};
    gStr = fieldnames(gPara); 
    
    % updates the parameter struct with the global parameters
    for i = 1:length(gStr); 
        eval(sprintf('p.%s = gPara.%s;',gStr{i},gStr{i})); 
    end
end