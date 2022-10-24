classdef DataOutputArray < handle
    
    % class properties
    properties
        
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
        function obj = DataOutputArray(hFig)
            
            % sets the input arguments
            obj.hFig = hFig;
            obj.hFigH = guidata(hFig);
            
            % initialises the class fields
            obj.initMainClassFields();
            
        end
        
        % --- initialises the class object fields
        function initMainClassFields(obj)     
            
            % global variables
            global nMet
            
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
            obj.appOut = obj.iData.appOut(:,obj.cTab);
            obj.expOut = obj.iData.expOut(:,obj.cTab);            
            obj.iOrder = tData.iPara{obj.cTab}{obj.iSel}{1};            
            
            % retrieves the boolean flags
            obj.sepGrp = getCheckValue(obj.hFigH.checkSepByApp);
            obj.sepExp = getCheckValue(obj.hFigH.checkSepByExpt);
            obj.sepDay = getCheckValue(obj.hFigH.checkSepByDay);            
            obj.numGrp = getCheckValue(obj.hFigH.checkNumGroups);
            obj.isHorz = get(obj.hFigH.radioAlignHorz,'value');
            
            % sets the other scalar fields
            obj.nApp = sum(obj.appOut);            
            obj.nMet = length(obj.iOrder);
            obj.nMetT = nMet;
            
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