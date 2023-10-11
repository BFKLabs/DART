% --- converts the 2D pregion parameters to positional vector arrays
function pPos = para2pos(Para)

% sets up the detection parameter struct (based on shape type)
switch Para.Type
    case 'Rectangle'
        % case is a rectangular region

        % memory allocation
        pPos = cell(size(Para.X0));
        
        % calculates the positional vector for each sub-region
        for i = 1:numel(Para.X0)
            pPos{i} = [Para.X0(i),Para.Y0(i),Para.W(i),Para.H(i)];
        end
        
    case 'Circle'
        % case is a circular region
        
        % memory allocation
        pPos = cell(size(Para.X0));
        
        % ensures the radii array is the correct size
        if numel(Para.R) ~= numel(Para.X0)
            Para.R = Para.R(1)*ones(size(Para.X0));
        end        
        
        % calculates the positional vector for each sub-region
        for i = 1:numel(Para.X0)
            % calculates the limits of the circular region
            xTmp = Para.X0(i) + Para.R(i)*Para.XC;
            yTmp = Para.Y0(i) + Para.R(i)*Para.YC;
            [xL,yL] = deal([min(xTmp),max(xTmp)],[min(yTmp),max(yTmp)]);
            
            % sets the positional vector
            pPos{i} = [xL(1),yL(1),diff(xL),diff(yL)];
        end
        
    case 'GeneralR'
        % case is a general repeating region
        
        % memory allocation
        pPos = cell(size(Para.X0));
                
        % calculates the positional vector for each sub-region
        for i = 1:numel(Para.X0)
            % calculates the limits of the circular region
            xTmp = Para.X0(i) + Para.XC;
            yTmp = Para.Y0(i) + Para.YC;
            [xL,yL] = deal([min(xTmp),max(xTmp)],[min(yTmp),max(yTmp)]);
            
            % sets the positional vector
            pPos{i} = [xL(1),yL(1),diff(xL),diff(yL)];
        end        
        
end