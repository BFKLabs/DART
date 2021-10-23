% --- sets up the auto detection parameter struct
function autoP = setupAutoDetectPara(iMov,pPos)

% initialisations
nApp = iMov.nRow*iMov.nCol;
% pPos = cell2cell(pPos,0);

% memory allocation
autoP = struct('X0',[],'Y0',[],'B',[],'Type',[],'isAuto',false);
autoP.B = cell(nApp,1);

% sets up the detection parameter struct (based on shape type)
switch iMov.mShape
    case 'Rect'
        % case is rectangular regions
        
        % sets the region type
        autoP.Type = 'Rectangle';
        
        % sets the region location points
        autoP.X0 = cellfun(@(x)(x(1)),pPos);
        autoP.Y0 = cellfun(@(x)(x(2)),pPos);
        autoP.W = cellfun(@(x)(x(3)),pPos);
        autoP.H = cellfun(@(x)(x(4)),pPos);
        
        % sets the rectangular binary regions
        for i = 1:nApp
            % retrieves the rectangle parameters
            [W,H] = deal(autoP.W(:,i),autoP.H(:,i));
            [X,Y] = deal(autoP.X0(:,i),autoP.Y0(:,i));
            szB = [length(iMov.iR{i}),length(iMov.iC{i})];            
            
            % sets up the region binary mask            
            autoP.B{i} = false(szB);                        
            [XB,YB] = meshgrid(1:szB(2),1:szB(1));
            pOfs = [iMov.iC{i}(1),iMov.iR{i}(1)]-1;
            
            % sets the region binary image
            for j = 1:length(X)
                [dXB,dYB] = deal(XB-(X(j)-pOfs(1)),YB-(Y(j)-pOfs(2)));
                Bnw = (dXB>=0) & (dXB<=W(j)) & (dYB>=0) & (dYB<=H(j));
                autoP.B{i} = autoP.B{i} | Bnw;
            end
        end
        
    case 'Circ'
        % case is circular regions

        % sets the region type
        autoP.Type = 'Circle';  
        
        % sets the region location points
        autoP.X0 = cellfun(@(x)(x(1)+x(3)/2),pPos);
        autoP.Y0 = cellfun(@(x)(x(2)+x(4)/2),pPos);
        autoP.R = cellfun(@(x)(x(3)/2),pPos);
        
        % sets the outline coordinates
        phi = linspace(0,2*pi,101)';
        [autoP.XC,autoP.YC] = deal(cos(phi),sin(phi));
        
        % sets the circular binary regions
        for i = 1:nApp
            % retrieves the rectangle parameters
            [X,Y,R] = deal(autoP.X0(:,i),autoP.Y0(:,i),autoP.R(:,i));
            szB = [length(iMov.iR{i}),length(iMov.iC{i})];
            
            % sets up the region binary mask            
            autoP.B{i} = false(szB);                        
            [XB,YB] = meshgrid(1:szB(2),1:szB(1));
            pOfs = [iMov.iC{i}(1),iMov.iR{i}(1)]-1;
            
            % sets the region binary image
            for j = 1:length(X)
                [dXB,dYB] = deal(XB-(X(j)-pOfs(1)),YB-(Y(j)-pOfs(2)));
                Bnw = sqrt(dXB.^2 + dYB.^2) <= R(j);
                autoP.B{i} = autoP.B{i} | Bnw;
            end
                
        end
        
end