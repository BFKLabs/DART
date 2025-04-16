classdef GenRegionDetect < handle
    
    % class properties
    properties
    
        % input arguments
        I
        iMov
        hProg

        % image arrays fields
        IbgE
        IbgE0
        BSmx
        
        % index array class fields
        iR
        iC
        xiR
        xiC
        
        % dimensioning class fields
        sz
        sz0        
        nRow
        nCol
        nReg
        
        % other class fields
        X0
        Y0
        xOfs
        yOfs
        xOfsF
        yOfsF        
        
        % boolean class fields
        calcOK = true;
        delProg = true;
        
        % fixed scalar fields
        dX = 10;
        dY = 10;
        rDel = 2;
        szDel = 5;  
        
        % other class fields
        ix = [1,1,2,2,1];
        iy = [1,2,2,1,1];
        pStr = {'Single Tracking','Multi Tracking'};
    
    end
    
    % --- class methods
    methods
        
        % --- class constructor
        function obj = GenRegionDetect(iMov,I,isMTrk)
            
            % sets the input arguments
            obj.I = I;
            obj.iMov = iMov;
                        
            % initialises the class fields
            obj.initClassFields(isMTrk);            
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj,isMTrk)
                                    
            % progressbar initialisations
            wStr = 'Initialising Class Objects...';
            tStr = sprintf('%s Region Optimisation',obj.pStr{1+isMTrk});
            obj.hProg = ProgBar(wStr,tStr);            
            
            % field retrieval
            pG = obj.iMov.posG;
            
            % sets up the row/column indices
            obj.iC = floor(pG(1)):ceil(sum(pG([1,3])));
            obj.iR = floor(pG(2)):ceil(sum(pG([2,4])));
            obj.sz = [length(obj.iR),length(obj.iC)];
            
            % array dimensioning
            obj.nRow = obj.iMov.pInfo.nRow;
            obj.nCol = obj.iMov.pInfo.nCol;    
            obj.nReg = obj.nCol*obj.nRow;         
            
            % sets the candidate image
            obj.IbgE0 = calcImageStackFcn(obj.I,'max');
            obj.IbgE = obj.IbgE0(obj.iR,obj.iC);      
            obj.sz0 = size(obj.IbgE0);                                                   
            
        end                        
                
        % -------------------------- %
        % --- PLOTTING FUNCTIONS --- %
        % -------------------------- %
        
        % --- plots the optimal grid configuration
        function plotOptimalSetup(obj)
            
            % initialisations
            [xLT,yLT] = deal(obj.xiC([1,end]),obj.xiR([1,end]));             
            
            % plots the image stack
            plotGraph('moviesel',obj.I); 
            hold on; 
                        
            % plots the horizontal markers
            for i = 2:obj.nRow
                plot(xLT,obj.xiR(i)*[1,1],'g--')
            end 
            
            % plots the vertical markers
            for i = 2:obj.nCol
                plot(obj.xiC(i)*[1,1],yLT,'g--'); 
            end 
            
            % plots the outer regions
            plot(xLT(obj.ix),yLT(obj.iy),'k');
            
        end    
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %        
        
        function IL = setupSubImageStack(obj)
        
            % sets up the local residual image
            IL = cellfun(@(x)(x(obj.iR,obj.iC)),obj.I,'un',0);        
            
        end        
        
    end    
    
end