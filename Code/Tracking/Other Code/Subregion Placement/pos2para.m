% --- converts the positional vector arrays to meaningful 2D parameters
function Para = pos2para(iMov,pPos)

% initialisations
nApp = iMov.nRow*iMov.nCol;

% retrieves the region shape string
if isfield(iMov,'mShape')
    Type = iMov.mShape;
else
    Type = 'Circ';
end

% memory allocation
Para = struct('X0',[],'Y0',[],'XC',[],'YC',[],'B',[],'pPos',[],'Type',Type);

% exits the function if no position data provided
if ~exist('pPos','var'); return; end

% sets the other fields
[Para.B,Para.pPos] = deal(cell(nApp,1),pPos);

% sets up the detection parameter struct (based on shape type)
switch iMov.mShape
    case 'Rect'
        % case is rectangular regions
        
        % sets the region type
        Para.Type = 'Rectangle';
        
        % sets the region location points
        Para.X0 = cellfun(@(x)(x(1)),pPos);
        Para.Y0 = cellfun(@(x)(x(2)),pPos);
        Para.W = cellfun(@(x)(x(3)),pPos);
        Para.H = cellfun(@(x)(x(4)),pPos);
        
        % sets the rectangular binary regions
        for i = 1:nApp
            % retrieves the rectangle parameters
            [W,H] = deal(Para.W(:,i),Para.H(:,i));
            [X,Y] = deal(Para.X0(:,i),Para.Y0(:,i));
            szB = [length(iMov.iR{i}),length(iMov.iC{i})];            
            
            % sets up the region binary mask            
            Para.B{i} = false(szB);                        
            [XB,YB] = meshgrid(1:szB(2),1:szB(1));
            pOfs = [iMov.iC{i}(1),iMov.iR{i}(1)]-1;
            
            % sets the region binary image
            for j = 1:length(X)
                [dXB,dYB] = deal(XB-(X(j)-pOfs(1)),YB-(Y(j)-pOfs(2)));
                Bnw = (dXB>=0) & (dXB<=W(j)) & (dYB>=0) & (dYB<=H(j));
                Para.B{i} = Para.B{i} | Bnw;
            end
        end
        
    case 'Circ'
        % case is circular regions

        % sets the region type
        Para.Type = 'Circle';  
        
        % sets the region location points
        Para.X0 = cellfun(@(x)(x(1)+x(3)/2),pPos);
        Para.Y0 = cellfun(@(x)(x(2)+x(4)/2),pPos);
        Para.R = cellfun(@(x)(x(3)/2),pPos);
        
        % sets the outline coordinates
        phi = linspace(0,2*pi,101)';
        [Para.XC,Para.YC] = deal(cos(phi),sin(phi));
        
        % sets the circular binary regions
        for i = 1:nApp
            % retrieves the rectangle parameters
            [X,Y,R] = deal(Para.X0(:,i),Para.Y0(:,i),Para.R(:,i));
            szB = [length(iMov.iR{i}),length(iMov.iC{i})];
            
            % sets up the region binary mask            
            Para.B{i} = false(szB);                        
            [XB,YB] = meshgrid(1:szB(2),1:szB(1));
            pOfs = [iMov.iC{i}(1),iMov.iR{i}(1)]-1;
            
            % sets the region binary image
            for j = 1:length(X)
                [dXB,dYB] = deal(XB-(X(j)-pOfs(1)),YB-(Y(j)-pOfs(2)));
                Bnw = sqrt(dXB.^2 + dYB.^2) <= R(j);
                Para.B{i} = Para.B{i} | Bnw;
            end
                
        end
        
end