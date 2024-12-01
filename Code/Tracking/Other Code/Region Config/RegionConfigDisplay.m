classdef RegionConfigDisplay < dynamicprops & handle
    
    % class properties
    properties
        
        % axes class objects
        hImg
        hSelP
        
        % temporary class fields
        nL
        xL
        yL
        szL
        Imap
        pInfo
        
        % static numeric fields
        lWidO = 3;
        lWidS = 2;
        fAlphaS = 0.6;
        ix = [1,1,2,2,1];
        iy = [1,2,2,1,1];
        
        % static character fields
        tStrOut = 'hOutline';
        
    end    
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end 
        
    % class methods
    methods
        
        % --- class constructor
        function obj = RegionConfigDisplay(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','hAx','hAxM',...
                      'iMov','iData','isMTrk','isMouseDown','p0'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end

        % ------------------------------------------- %        
        % --- AXES CONFIGURATION UPDATE FUNCTIONS --- %
        % ------------------------------------------- %
        
        % --- initialises the class fields
        function resetConfigAxes(obj,resetAxes)
            
            % sets the default input arguments
            if ~exist('resetAxes','var'); resetAxes = true; end
            
            % field retrieval
            obj.pInfo = obj.objB.getDataSubStruct();
            obj.calcRegionScaleFactor();            
                        
            % sets the x/y axis limits
            obj.xL = [0,obj.pInfo.nCol] + 0.5;
            obj.yL = [0,obj.pInfo.nRow*obj.nL] + 0.5;
            obj.szL = [obj.yL(2),obj.xL(2)] - 0.5;
            
            if resetAxes
                % turns the axes hold on
                hold(obj.hAx,'on');
                
                % case is resetting the configuration plot
                obj.clearConfigAxes();
                                
                % sets up the outer region line objects
                obj.setupOuterRegions();
                if ~(obj.iData.is2D || obj.isMTrk)
                    % sets up the inner region line objects (1D only)
                    obj.setupInnerRegions();
                end                
                
                % turns the axes hold off
                hold(obj.hAx,'off');                
                
            else
                % case is updating the patch colours
                
                % sets up the region index map
                obj.setupGroupIndexMap();
                obj.hImg.CData = uint8(obj.Imap);
            end
            
            % creates the group patches (2D only)
            if obj.iData.is2D || obj.isMTrk
                obj.createGroupOutlines()
            end            
            
            % updates the control button properties
            obj.objB.setContButtonProps()
            
        end

        % ----------------------------- %        
        % --- PLOT OBJECT FUNCTIONS --- %
        % ----------------------------- %
                
        % --- creates the outer region markers
        function setupOuterRegions(obj)
            
            % initialisations
            xiR = 0.5 + obj.nL*(1:(obj.pInfo.nRow-1))';
            xiC = 0.5 + (1:(obj.pInfo.nCol-1))';
            lWid = 1 + 2*(~(obj.iData.is2D || obj.isMTrk));
            
            % sets the coordinates of the outline markers
            xR = arr2vec(repmat([obj.xL,NaN],length(xiR),1)');
            yR = arr2vec((xiR.*repmat([1,1,NaN],length(xiR),1))');            
            xC = arr2vec((xiC.*repmat([1,1,NaN],length(xiC),1))');
            yC = arr2vec(repmat([obj.yL,NaN],length(xiC),1)');
            
            % plots the region outline markers
            plot(obj.hAx,[xR;xC],[yR;yC],'k','linewidth',lWid);
            
            % plots the outline border
            [xLO,yLO] = deal(obj.xL(obj.ix),obj.yL(obj.iy));
            plot(obj.hAx,xLO,yLO,'k','linewidth',obj.lWidO)
            
        end
        
        % --- creates the inner region markers
        function setupInnerRegions(obj)
            
            % memory allocation
            [xP,yP] = deal(cell(obj.pInfo.nRow,obj.pInfo.nCol));
            
            % sets up the inner x/y coordinates for each region
            for i = 1:obj.pInfo.nRow
                for j = 1:obj.pInfo.nCol
                    % region field retrieval
                    nFly = obj.pInfo.nFly(i,j);
                    xiF = (1/nFly)*(1:(nFly-1))';
                    
                    % sets the region x-coordinates
                    xPF = repmat((j-1)+[0,1,NaN],nFly-1,1);
                    xP{i,j} = arr2vec(xPF') + 0.5;
                    
                    % sets the region y-coordinates
                    yPF = (i-1) + xiF.*repmat([1,1,NaN],nFly-1,1);
                    yP{i,j} = obj.nL*arr2vec(yPF') + 0.5;
                end
            end
            
            % plots the final inner markers
            [xPT,yPT] = deal(cell2mat(xP(:)),cell2mat(yP(:)));
            plot(obj.hAx,xPT,yPT,'k','Linewidth',0.5);
            
        end
        
        % --- creates the group outlines
        function createGroupOutlines(obj)
            
            % turns the axes hold on
            hold(obj.hAx,'on');              
            
            if obj.isMTrk
                % case is multi-tracking (custom grid only)
                isGrid = false;
                
            else
                % case is single-tracking (evenly spaced or custom grid)                
                isGrid = obj.objB.objT{2}.hRadioR{1}.Value;
            end
            
            if isGrid
                % case is using an evenly spaced grid
                if obj.pInfo.nGrp == 1
                    % only one group, so use only 1 row/column grouping
                    [nCG,nRG] = deal(1);
                else
                    % more than one group, so use the set values
                    [nCG,nRG] = deal(obj.pInfo.nColG,obj.pInfo.nRowG);
                end                
                
                % calculates the x/y grid range
                dX = diff(get(obj.hAx,'xlim'))/nCG;
                dY = diff(get(obj.hAx,'ylim'))/nRG;              
                
                % case is the sub-regions are in grid formation
                for i = 1:nRG
                    for j = 1:nCG
                        % creates the patch object
                        xP = dX*(j+[-1,0]) + 0.5;
                        yP = dY*(i+[-1,0]) + 0.5;
                        plot(obj.hAx,xP(obj.ix),...
                            yP(obj.iy),'k','Linewidth',obj.lWidO)
                    end
                end
            
            else
                % case is using a custom grid setup
                
                % initialisations
                iGrp = obj.pInfo.iGrp;
                szG = size(iGrp);
                
                % retrieves the existing outline coordinates
                hOut = deal(findall(obj.hAx,'tag',obj.tStrOut));
                [isUse,iOut] = deal(false(size(hOut)),0);
                
                %
                for i = unique(iGrp)'    
                    % determines the groups for the current
                    CC = bwconncomp(iGrp == i,4);
                    jGrp = CC.PixelIdxList;
                    
                    for j = 1:length(jGrp)
                        % retrieves the outline of the current group
                        B0 = bwfill(setGroup(jGrp{j},szG),'holes');
                        if any(szG == 1)
                            B = B0;
                        else
                            B = interp2(double(B0),2,'nearest');
                        end

                        % retrieves the outline coordinates
                        P = imfill(boundarymask(padarray(B,[1,1])),'holes');
                        Pc0 = bwboundaries(P);

                        % sets the outline coordinates
                        Pc = roundP(Pc0{1}/4);
                        Pc = Pc(sum(abs(diff([-[1,1];Pc],[],1)),2)>0,:);                    

                        % updates/creates the outline markers
                        [ii,iOut] = deal([(1:size(Pc,1)),1],iOut+1);
                        if iOut > length(hOut)
                            % if there is
                            plot(obj.hAx,Pc(ii,2)+0.5,Pc(ii,1)+0.5,...
                              'k','LineWidth',obj.lWidO,'Tag',obj.tStrOut);
                            
                        else
                            % otherwise, update the line coordinates
                            set(hOut(iOut),...
                                'XData',Pc(ii,2)+0.5,'YData',Pc(ii,1)+0.5);
                            isUse(iOut) = true;
                        end
                    end
                end

                % if there are any lines not used, then delete them
                if any(~isUse)
                    delete(hOut(~isUse));
                end                    
            end
            
            % turns the axes hold off
            hold(obj.hAx,'off');            
            
        end
        
        % --- selection patch update function
        function updateSelectionPatch(obj,fType,varargin)
            
            switch fType
                case 'add'
                    % case is adding the selection patch
                    
                    % sets the selection patch coordinates
                    if obj.iData.is2D || obj.isMTrk
                        % case is for a 2D expt setup
                        [xP,yP] = deal(obj.p0(1)+[-1,0],obj.p0(2)+[-1,0]);
                        
                    else
                        % determines the region indices
                        indR = obj.getRegionIndices1D(obj.p0);
                        xP = obj.p0(1) + [-1,0];
                        
                        % case is for a 1D expt setup
                        if obj.pInfo.isFixed
                            % case is using sub-grouping
                            yOfs = (indR(1)-1)*obj.nL;
                            nFly = obj.pInfo.nFly(indR(1),indR(2));
                            yP = yOfs + (indR(3) + [-1,0])*(obj.nL/nFly);
                            
                        else
                            % case is using full grouping                            
                            yP = (indR(1)+[-1,0])*obj.nL;
                        end
                    end
                    
                    % creates the selection marker
                    pCol = varargin{1};
                    obj.hSelP = patch(xP(obj.ix)+0.5,yP(obj.iy)+0.5,...
                        pCol,'Parent',obj.hAx,'Tag','hSelP',...
                        'LineWidth',3,'FaceAlpha',obj.fAlphaS);
                    
                case 'update'
                    % case is updating the selection patch
                    
                    % sets the input arguments
                    pU = varargin{1};
                    
                    % sets selection patch coordinates (based on expt type)
                    if obj.iData.is2D || obj.isMTrk
                        % case is for a 2D expt setup
                        xP = [min(pU(1),obj.p0(1))-1,max(pU(1),obj.p0(1))];
                        yP = [min(pU(2),obj.p0(2))-1,max(pU(2),obj.p0(2))];
                        
                    else
                        % determines the region indices
                        indR0 = obj.getRegionIndices1D(obj.p0);
                        indRU = obj.getRegionIndices1D(pU);
                        xP = [min(pU(1),obj.p0(1))-1,max(pU(1),obj.p0(1))];                        
                        
                        % case is for a 1D expt setup
                        if obj.pInfo.isFixed
                            % case is using sub-grouping
                            [xP,yP] = obj.getSubRegionCoord(indR0,indRU,1);
                            
                        else
                            % case is using full grouping
                            yP = [(min(indR0(1),indRU(1))-1)*obj.nL,...
                                   max(indR0(1),indRU(1))*obj.nL];
                        end
                    end                    
                    
                    try
                        % updates the patch coordinates
                        if length(xP) == 2
                            obj.hSelP.XData = xP(obj.ix) + 0.5;
                            obj.hSelP.YData = yP(obj.iy) + 0.5;
                        else
                            obj.hSelP.XData = xP([(1:end),1]) + 0.5;
                            obj.hSelP.YData = yP([(1:end),1]) + 0.5;
                        end
                    catch
                        % if there was an error, then delete the patch
                        obj.updateSelectionPatch('delete');
                        
                        % resets the mouse down flag
                        obj.isMouseDown = false;
                    end
                    
                case 'delete'
                    % case is deleting the selection patch
                    
                    % deletes and clears the selection patch (if it exists)
                    if ~isempty(obj.hSelP)
                        % deletes the patch object
                        if isa(obj.hSelP,'matlab.graphics.primitive.Patch')
                            delete(obj.hSelP);
                        end
                            
                        % clears the selection object field
                        obj.hSelP = [];
                    end
            end
            
        end

        % ----------------------------- %
        % --- GROUP PATCH FUNCTIONS --- %
        % ----------------------------- %
        
        % --- sets up the group index map array
        function setupGroupIndexMap(obj)
            
            % sets up the plot properties
            iGrp = obj.pInfo.iGrp;
            pCol = 255*getAllGroupColours(length(obj.pInfo.gName));            
            
            % memory allocation
            obj.Imap = pCol(1)*ones([obj.szL,3]);
            
            if obj.iData.is2D || obj.isMTrk
                % case is multi-tracking/2D single-tracking expts
                
                % index map is set to the group index array
                for i = 1:obj.pInfo.nRow
                    for j = 1:obj.pInfo.nCol
                        % retrieves the region colour
                        pColG = pCol(iGrp(i,j)+1,:);
                        
                        % sets the colours for each phase
                        for k = 1:length(pColG)
                            obj.Imap(i,j,k) = pColG(k);
                        end
                    end
                end
                
            else
                % case is 1D single-tracking expts
                
                % memory allocation
                [gID,nFly] = deal(obj.pInfo.gID,obj.pInfo.nFly);
                
                % sets up the index map for each row/column
                for i = 1:obj.pInfo.nRow
                    % row pre-calculations
                    rwOfs = (i-1)*obj.nL;
                    
                    for j = 1:obj.pInfo.nCol
                        % column pre-calculations
                        dR = obj.nL/nFly(i,j);
                    
                        % sets the index map for each sub-region
                        for k = 1:nFly(i,j)
                            % sets the index map row indices
                            pColG = pCol(gID{i,j}(k)+1,:);
                            iRL = rwOfs + ((dR*(k-1)+1):(dR*k));

                            % sets the mapping value
                            for iCh = 1:length(pColG)
                                obj.Imap(iRL,j,iCh) = pColG(iCh);
                            end
                        end
                    end
                end                
            end
                        
        end

        %
        function varargout = getSubRegionCoord(obj,ind0,ind1,isCoord)
            
            % field retrieval and initialisations
            ind = [ind0(:),ind1(:)];           
            xiC = min(ind(2,:)):max(ind(2,:));
            obj.pInfo = obj.objB.getDataSubStruct(false);            
              
            % calculates the vertical range for start/finish indices
            yRng = zeros(2);
            for i = 1:2
                dR = obj.nL/obj.pInfo.nFly(ind(1,i),ind(2,i));
                yRng(i,:) = (ind(1,i)-1)*obj.nL + (ind(3,i)+[-1,0])*dR;
            end
            
            % determines the indices of the min/max vertical range
            [iLo,iHi] = deal(argMin(yRng(:,1)),argMax(yRng(:,1)));
            yOfs = ([ind(1,iLo),ind(1,iHi)]-1)*obj.nL;            
            
            % sets the vertical limits over all columns
            iFly = zeros(2,length(xiC));
            [yC,xC] = deal(zeros(2,2*length(xiC)));
            for i = 1:length(xiC)
                % pre-calculations
                jj = (i-1)*2 + (1:2);
                xC(:,jj) = repmat(xiC(i)+[-1,0],2,1);
                
                % calculates the lower limit index/coordinates
                dRLo = obj.nL/obj.pInfo.nFly(ind(1,iLo),xiC(i));
                iFly(1,i) = ceil((yRng(iLo,1) - yOfs(1))/dRLo) + 1;
                yC(1,jj) = yOfs(1) + (iFly(1,i) - 1)*dRLo;
                
                % calculates the upper limit index/coordinates
                dRHi = obj.nL/obj.pInfo.nFly(ind(1,iHi),xiC(i));
                iFly(2,i) = floor((yRng(iHi,2) - yOfs(2))/dRHi);                
                yC(2,jj) = yOfs(2) + iFly(2,i)*dRHi;                
            end 
            
            %
            if isCoord
                % case is outputting coordinates
                varargout = {[xC(1,:),flip(xC(2,:))],...
                             [yC(1,:),flip(yC(2,:))]};
                
            else
                % case is outputting region indices
                
                % pre-calculations
                iFlyT = zeros(1,2);
                xiR = min(ind(1,:)):max(ind(1,:));
                
                % variable output memory allocation
                varargout = cell(1,3);                
                varargout{1} = xiR;
                varargout{2} = xiC;
                varargout{3} = cell(length(xiR),length(xiC));
                
                % sets the sub-region indices
                for j = 1:length(xiC)                
                    for i = 1:length(xiR)
                        % sets the first fly index value
                        if i == 1
                            iFlyT(1) = iFly(1,j);                            
                        else
                            iFlyT(1) = 1;
                        end
                        
                        % sets the last fly index value
                        if i == length(xiR)
                            iFlyT(2) = iFly(2,j);
                        else
                            iFlyT(2) = obj.pInfo.nFly(xiR(i),xiC(j));                            
                        end
                        
                        % sets the full selected fly index array
                        varargout{3}{i,j} = iFlyT(1):iFlyT(2);
                    end
                end
            end
            
        end
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- resets the configuration axes
        function clearConfigAxes(obj)
            
            % clears the axis 
            cla(obj.hAx)
            axis(obj.hAx,'ij');
            
            % sets the axis limits
            set(obj.hAx,'xLim',obj.xL,'yLim',obj.yL);            
        
            % sets up the region index map
            obj.setupGroupIndexMap();
            obj.hImg = image(obj.hAx,uint8(obj.Imap));
            
            % sets the axes properties
            set(obj.hAx,'xticklabel',[],'yticklabel',[],...
                'box','on','xcolor','w','ycolor','w','ticklength',[0,0]);
            
            % turns the axis hold on
            hold(obj.hAx,'on')            
            
        end        

        % --- calculates the region scale factor
        function calcRegionScaleFactor(obj)
            
            if obj.iData.is2D || obj.isMTrk
                % case is multi-tracking/2D single-tracking expts
                obj.nL = 1;
                
            else
                % case is 1D single-tracking expts
                obj.nL = obj.calcArrayLCM(obj.pInfo.nFly);
            end
            
        end
        
        % --- retrieves the indices of the selected 1D regions
        function indR = getRegionIndices1D(obj,mPosAx)
            
            % sets the default input arguments
            if ~exist('mPosAx','var')
                mPosAx = ceil(get(obj.hAx,'CurrentPoint')-0.5);                
            end
            
            % field retrieval
            iCol = max(1,min(obj.pInfo.nCol,mPosAx(1,1)));
            iRow = max(1,min(obj.pInfo.nRow,ceil(mPosAx(1,2)/obj.nL)));
            indR = [iRow,iCol];            
            
            % retrieves the region data struct
            obj.pInfo = obj.objB.getDataSubStruct();            
            
            % determines if sub-region selection was selected
            if obj.pInfo.isFixed
                % determines the sub-region that was selected
                nFly = obj.pInfo.nFly(iRow,iCol);
                iReg = ceil(nFly*(mPosAx(1,2) - (iRow-1)*obj.nL)/obj.nL);
                
                % appends the sub-region index to the index array
                indR = [indR,iReg];
            end
            
        end
        
    end     
    
    % static class methods
    methods (Static)
        
        % --- calculates the lcm over the array, Y
        function L = calcArrayLCM(Y)
            
            % initialisations
            Y = arr2vec(Y);
            
            % calculates the LCM over the entire array
            L = Y(1);
            for i = 2:numel(Y)
                L = lcm(L,Y(i));
            end
            
        end
        
    end
    
    % private class methods
    methods (Access = private)
        
        % --- sets a class object field
        function SetDispatch(obj, propname, varargin)
            
            obj.objB.(propname) = varargin{:};
            
        end
        
        % --- gets a class object field
        function varargout = GetDispatch(obj, propname)
            
            varargout{:} = obj.objB.(propname);
            
        end
        
    end
    
end