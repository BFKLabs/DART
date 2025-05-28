% --- sets/initialises the fields of the calculation/plot data struct --- %
function p = setParaFields(varargin)

% sets/initialises the parameter struct (based on the input arguments)
p = struct('Tab',[],'Name',[],'Type','None','Value',[],'Para',[],...
           'Lim',[],'Enable',[],'TTstr',[],'isFixed',false);
if (nargin == 1)    
    % initialises the parameter struct (for each apparatus)        
    p = repmat(p,varargin{1},1);
else
    % sets the name, type and parameter string fields
    Value = varargin{3};
    [Type,p.Type] = deal(varargin{2}); 
    p.isFixed = strContains(p.Type,'Fixed');
    
    % sets the tab name (if provided)
    if (isempty(varargin{1}))
        p.Tab = '';
    else
        p.Tab = varargin{1};
    end
    
    % updates the other fields based on the data type
    switch (Type)
        case ('Time') 
            % case is the time limit parameter struct
            
            % memory allocation
            p.Value = struct('Lower',[],'Upper',[],'Name',[]);           
            T0 = floor(vec2sec([0,Value.iExpt(1).Timing.T0(4:end)]));
            Tf = ceil(T0 + Value.T{end}(end));  
            Tofs = 60*((Tf - T0) > 600);
            
            % sets the current lower limit values
            p.Value.Lower = sec2vec(T0+Tofs); p.Value.Lower(end) = 0;                        
            p.Value.Lower(end) = (p.Value.Lower(2) >= 12);
            p.Value.Lower(2) = mod(p.Value.Lower(2),12);
               
            % sets the current upper limit values
            p.Value.Upper = sec2vec(Tf-Tofs); p.Value.Upper(end) = 0;
            p.Value.Upper(end) = (p.Value.Upper(2) >= 12);
            p.Value.Upper(2) = mod(p.Value.Upper(2),12);
            
            % sets the limit fields
            [p.Lim,p.Name,p.Para] = deal([T0,Tf],'Time','pTime');

        case ('Subplot') 
            % case is the time subplot parameter struct           
            
            % memory allocation
            [nCount,spName] = deal(varargin{3},varargin{4});
            [canComb,hasRC] = deal(varargin{5},varargin{6});
            [nRow,nCol] = detSubplotDim(nCount);                       
            
            % sets the subplot value struct and the limits
            p.Value = struct('nRow',nRow,'nCol',nCol,'isPlot',...
                             true(nCount,1),'Name',[],'isComb',false,...
                             'canComb',canComb,'hasRC',hasRC);                    
                         
            p.Value.Name = spName;
            [p.Lim,p.Name,p.Para] = deal([1 nCount],'Subplot','pSub');  
            
        case ('Stim') 
            % case is the stimuli response signal selection struct
            
            % set the input arguments
            [pData,pStr,pType] = deal(varargin{3},varargin{4},varargin{5});
            [p.Name,p.Lim,p.Para] = deal('Stim',pType,pStr);
            
            % determines if there is a matching field within the
            % calculation parameter struct. if so, then updates the
            % value/parameter strings of the data struct
            if ~isempty(pStr)
                switch pStr
                    case {'appName','appNameR'}
                        % special case - region/sub-region names
                        p.Value = pStr;
                        
                    otherwise
                        % case is the other parameter types
                        ii = arrayfun(@(x)(strcmp(x.Para,pStr)),pData.cP);
                        if any(ii)
                            p.Value = pData.cP(ii).Value{1};
                        end
                end
            end
            
        otherwise
            % case is the other parameter type
            [p.Para,p.Name,p.Value] = deal(varargin{4},varargin{5},Value);
            if strcmp(Type,'Number'); p.Lim = varargin{6}; end            
            if (nargin == 7); p.Enable = varargin{7}; end 
    end
end
