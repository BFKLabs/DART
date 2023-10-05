classdef DataOutputArray < handle
    
    % class properties
    properties
        
        % input argument fields
        hProg        
        
        % main class fields
        hFig
        hFigH
        Data
        DataN        
        
        % important data struct fields
        Y
        iData
        pData
        plotD
        snTot
        
        % table data fields
        iSel
        stInd
        appOut
        expOut
        iOrder
        
        % boolean flag fields
        sepExp
        sepGrp
        sepDay
        numGrp
        isHorz
        useGlob
        nonZeroTime
        
        % other scalar fields
        cTab
        nExp
        nApp
        nMet      
        nMetT

    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = DataOutputArray(hFig,hProg)
            
            % sets the input arguments
            obj.hFig = hFig;            
            obj.hFigH = guidata(hFig);
            
            % sets the progress loadbar (if provided)
            if exist('hProg','var'); obj.hProg = hProg; end
            
            % initialises the class fields
            obj.initMainClassFields();
            
        end
        
        % --- initialises the class object fields
        function initMainClassFields(obj)     
            
            % retrieves the important data fields
            obj.iData = getappdata(obj.hFig,'iData');
            obj.pData = getappdata(obj.hFig,'pData');
            obj.plotD = getappdata(obj.hFig,'plotD');
            obj.snTot = getappdata(obj.hFig,'snTot');
            
            % retrieves the important indices
            obj.cTab = obj.iData.cTab;
            
            % sets the table data fields
            tData = obj.iData.tData; 
            obj.iSel = tData.iSel(obj.cTab);
            obj.stInd = tData.stInd{obj.cTab};
            obj.Y = obj.iData.getData(obj.iSel);
            
            % sets the other fields
            obj.appOut = obj.iData.getAppOut();
            obj.expOut = obj.iData.getExpOut();            
            obj.iOrder = tData.iPara{obj.cTab}{obj.iSel}{1};            
            
            % retrieves the boolean flags
            obj.sepGrp = getCheckValue(obj.hFigH.checkSepByApp);
            obj.sepExp = getCheckValue(obj.hFigH.checkSepByExpt);
            obj.sepDay = getCheckValue(obj.hFigH.checkSepByDay);            
            obj.numGrp = getCheckValue(obj.hFigH.checkNumGroups);
            obj.useGlob = getCheckValue(obj.hFigH.checkGlobalIndex);
            obj.nonZeroTime = getCheckValue(obj.hFigH.checkZeroTime);
            obj.isHorz = get(obj.hFigH.radioAlignHorz,'value');
            
            % sets the other scalar fields
            obj.nApp = sum(obj.appOut);            
            obj.nMet = length(obj.iOrder);
            obj.nMetT = obj.iData.nMet;
            
        end
       
        % --- combines the data in DataF0 into a full array
        function combineFinalArray(obj,DataF0,pOfs)
            
            % sets the row/column offset
            if exist('pOfs','var')
                [rOfs,cOfs] = deal(pOfs(1),pOfs(2));
            else
                [rOfs,cOfs] = deal(1);
            end
            
            % initialisations            
            nGrp = length(DataF0);           
            szD = cell2mat(cellfun(@size,DataF0(:),'un',0));                        
            
            % data array memory allocation
            if obj.isHorz
                % case is the data is horizontally aligned
                nRowMx = max(szD(:,1));
                obj.Data = strings(nRowMx+rOfs,sum(szD(:,2))+(nGrp+1)+cOfs);
                
            else
                % case is the data is vertically aligned
                nColMx = max(szD(:,2));
                obj.Data = strings(sum(szD(:,1))+(nGrp+1)+rOfs,nColMx+cOfs);                
            end
            % sets the data into the final array
            for i = 1:numel(DataF0)
                % sets the data for the current block
                iR = (1:size(DataF0{i},1)) + rOfs;
                iC = (1:size(DataF0{i},2)) + cOfs;
                obj.Data(iR,iC) = DataF0{i};
                
                % increments the column offset
                if obj.isHorz
                    cOfs = (cOfs + 1) + size(DataF0{i},2);
                else
                    rOfs = (rOfs + 1) + size(DataF0{i},1);
                end
                
                % clears the temporary array
                DataF0{i} = [];                
            end            
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- ensures the row counts match between the two arrays, X & Y 
        function [X,Y] = matchRowCount(X,Y)
        
            % initialisations
            [a,b] = deal({''},'');
            
            % ensures the arrays are the correct size
            dnRow = size(X,1) - size(Y,1);
            if dnRow > 0
                mGap = repmat(a,dnRow,1);
                Y = combineCellArrays(mGap,Y,0,b);
            elseif dnRow < 0
                mGap = repmat(a,-dnRow,1);
                X = combineCellArrays(mGap,X,0,b);
            end        
        
        end
            
    end
    
end