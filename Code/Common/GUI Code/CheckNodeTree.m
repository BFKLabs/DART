classdef CheckNodeTree < handle
    
    % properties
    properties
    
        % inputs arguments
        fTree
        hPanelP
        
        % java object handles
        hTree
        hRoot
        jTree
        
        % other class fields
        Iicon
        widImg
        postToggleFcn
        
        % fixed scalar/string fields
        dX = 10;
        iType = {'Unchecked','Mixed','Checked'};
        
    end
    
    % class methods
    methods
       
        % --- class constructor
        function obj = CheckNodeTree(hPanelP,fTree)
            
            % sets the input arguments
            obj.fTree = fTree;
            obj.hPanelP = hPanelP;
            
            % initialises the class fields/objects
            obj.initClassFields();
            obj.initClassObjects();
            
        end
        
        % --- initialises the class objects
        function initClassFields(obj)
                        
            % memory allocation
            obj.Iicon = cell(length(obj.iType),2);
            for i = 1:length(obj.iType)
                [I,Imap] = obj.getIconArray(obj.iType{i});
                if ~isempty(I)
                    % creates the icon image
                    obj.Iicon{i,1} = im2java(I,Imap);
                    
                    % sets up the parent node icon
                    Imap(2,:) = [0.93,0.69,0.13];
                    obj.Iicon{i,2} = im2java(I,Imap);
                    
                    % sets the image width (if not set)
                    if isempty(obj.widImg)
                       obj.widImg = obj.Iicon{i,1}.getWidth;
                    end
                end
            end
                
        end
        
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % parameters
            N = 2.5;
            
            % java import
            import javax.swing.*
            import javax.swing.tree.*;
            import com.mathworks.mwswing.checkboxtree.*
            
            % create top node
            obj.hRoot = uitreenode('v0','root',obj.fTree.Text,[],0);            
            obj.createChildNodes(obj.hRoot,obj.fTree);
           
            % create the tree model
            [obj.hTree,hC] = uitree('v0','Parent',obj.hPanelP);
            obj.hTree.setModel(DefaultTreeModel(obj.hRoot));
            
            % creates the tree object
            obj.jTree = handle(obj.hTree.getTree,'CallbackProperties');
            set(obj.jTree,'MousePressedCallback',@obj.updateIcon);            
            
            % sets the container properties            
            dtPos = [1,(1+N),-2,-(3+N)]*obj.dX;
            tPos = [0,0,obj.hPanelP.Position(3:4)] + dtPos;            
            set(hC,'Parent',obj.hPanelP,'Position',tPos);            
            
        end        
        
        % --- mouse click callback function
        function updateIcon(obj,~,evnt)
            
            % retrieves the current path
            [pX,pY] = deal(evnt.getX,evnt.getY);
            tPath = obj.jTree.getPathForLocation(pX, pY);            
            
            % determines if the mouse click is by the icon
            if isempty(tPath)
                % case is no path was found
                return
            elseif pX > (obj.jTree.getPathBounds(tPath).x + obj.widImg)
                % case is the mouse click was not by the icon
                return
            end
                
            % retrieves the node component
            hNode = tPath.getLastPathComponent;                        
            if hNode.isRoot
                % ignore the root node
                return
            
            elseif hNode.isLeaf
                % if a leaf node, then 
                hNodeP = hNode.getParent;
                hNodeC = obj.getChildNodes(hNodeP);
                
                % toggles the node icon/values
                obj.toggleNodeValue(hNode);
                
                % 
                nVal = cellfun(@(x)(x.getValue),hNodeC,'un',0);
                isM = strcmp(nVal,'Checked');
                indM = find(sum(isM) >= [0,1,length(nVal)],1,'last');
                obj.toggleNodeValue(hNodeP,obj.iType{indM});
                
            else
                % otherwise, set the child icon values
                hNodeC = obj.getChildNodes(hNode);
                
                % toggles the checkbox values
                chkStateNw = obj.toggleNodeValue(hNode);
                cellfun(@(x)(...
                    obj.toggleNodeValue(x,chkStateNw)),hNodeC,'un',0);
            end            
            
        end
        
        % --- toggles the node icon/value
        function chkState = toggleNodeValue(obj,hNode,chkState)
            
            if ~exist('chkState','var')
                switch hNode.getValue
                    case 'Checked'
                        chkState = 'Unchecked';
                        
                    case 'Unchecked'
                        chkState = 'Checked';
                        
                    case 'Mixed'
                        chkState = 'Unchecked';                        
                end
            end
            
            % sets the row/column indices
            iRow = strcmp(obj.iType,chkState);
            iCol = 1 + hNode.getParent.isRoot;
            
            % updates the icon
            hNode.setValue(chkState);
            hNode.setIcon(obj.Iicon{iRow,iCol});
            obj.jTree.treeDidChange();            
            
            % runs the post toggle function (if it exists)
            if ~isempty(obj.postToggleFcn)
                obj.postToggleFcn();
            end
                
        end

        % --- creates the children nodes
        function createChildNodes(obj,hNodeP,fTreeP)
            
            % sets the column index
            iCol = 1 + hNodeP.isRoot;
            
            % creates the children nodes
            for i = 1:length(fTreeP.Child)
                % creates the new node
                nTxt = fTreeP.Child{i}.Text;
                hNodeC = uitreenode('v0','Checked',nTxt, [], 0);
                hNodeC.setIcon(obj.Iicon{3,iCol});
                
                % adds the new node to the parent node
                hNodeP.add(hNodeC);
                
                % creates the children nodes
                if ~isempty(fTreeP.Child{i}.Child)
                    obj.createChildNodes(hNodeC,fTreeP.Child{i});
                end
            end
            
        end
        
    end
    
    % static class methods
    methods (Static)
        
        % --- retrieves the icon arrays (based on type)
        function [I,Imap] = getIconArray(iType)
            
            switch iType
                case 'Checked'
                    I = uint8(...
                        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,0,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,0,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,0,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,0,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,0,0,1,1,2,2,3,1;
                        2,2,1,0,0,1,1,0,0,1,1,1,2,2,3,1;
                        2,2,1,1,0,0,0,0,1,1,1,1,2,2,3,1;
                        2,2,1,1,0,0,0,0,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,0,0,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,0,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1]);
                    Imap = [
                        0.023529,0.4902,0;
                        1,1,1;
                        0,0,0;
                        0.50196,0.50196,0.50196;
                        0.50196,0.50196,0.50196;
                        0,0,0;
                        0,0,0;
                        0,0,0];                    
                    
                case 'Unchecked'
                    % case is the unchecked box
                    I = uint8(...
                        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1]);
                    Imap = [
                        0.023529,0.4902,0;
                        1,1,1;
                        0,0,0;
                        0.50196,0.50196,0.50196;
                        0.50196,0.50196,0.50196;
                        0,0,0;
                        0,0,0;
                        0,0,0];
                                        
                case 'Mixed'
                    % case is a mixed selection
                    I = uint8(...
                        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,1,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,4,4,4,4,4,4,4,4,1,2,2,3,1;
                        2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1;
                        1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1]);
                    Imap = [
                        0.023529,0.4902,0;
                        1,1,1;
                        0,0,0;
                        0.50196,0.50196,0.50196;
                        0.50196,0.50196,0.50196;
                        0,0,0;
                        0,0,0;
                        0,0,0];
            end
            
            
        end
        
            
        function hNodeC = getChildNodes(hNodeP)
            
            xiC = 1:hNodeP.getChildCount;
            hNodeC = arrayfun(@(x)(hNodeP.getChildAt(x-1)),xiC,'un',0);
            
        end
        
    end
    
end