classdef BlobCNNMenus < dynamicprops & handle
    
    % properties
    properties
    
        % main class fields
        hMenuP
        
        % string class field
        dDir
        mStr0 = 'hMenuOpt';
        tStrS = 'Set Model File';
        tStrL = 'Select Model File';
        fMode = {'*.nmf','Network Model File (*.nmf)'};
        
    end
    
    % private class properties
    properties (Access = private)
        
        objB
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = BlobCNNMenus(objB)
            
            % sets the input arguments
            obj.objB = objB;
            
            % initialises the class fields/objects
            obj.linkParentProps();
            obj.initClassFields();
            obj.initClassObjects();            
                        
        end
        
        % -------------------------------------- %
        % --- CLASS INITIALISATION FUNCTIONS --- %
        % -------------------------------------- %        
        
        % --- initialises the class object fields with that parent object
        function linkParentProps(obj)
            
            % parent fields strings
            fldStr = {'hFig','sTypeCNN','pCNN'};
            
            % connects the base/child objects
            for propname = fldStr
                metaprop = addprop(obj, propname{1});
                metaprop.SetMethod = @(obj, varargin) ...
                    SetDispatch(obj, propname{1}, varargin{:});
                metaprop.GetMethod = @(obj)GetDispatch(obj, propname{1});
            end
            
        end
        
        % --- initialises the class fields
        function initClassFields(obj)
            
            % sets the default output directory (movie directory)
            obj.dDir = obj.hFig.mObj.Path;
            
        end
            
        % --- initialises the class objects
        function initClassObjects(obj)
            
            % initialisations
            mStrO = {'Classification Mode',...
                     'Training Mode',...
                     'Offline Mode'};
                        
            % creates the menu items
            obj.hMenuP = uimenu(obj.hFig,'Label','Classifier',...
                                         'Tag','menuClassifier');

            % creates the load/network menu items
            uimenu(obj.hMenuP,'Label','Load Network Model',...
                          'Callback',@obj.menuLoadModel,'Tag','hLoad');
            uimenu(obj.hMenuP,'Label','Save Network Model',...
                          'Callback',@obj.menuSaveModel,'Tag','hSave');
                      
            % creates the solver option menu/sub-menus
            hMenuO = uimenu(obj.hMenuP,'Label','Classification Options',...
                                       'Separator','On');
            for i = 1:length(mStrO)
                cbFcnO = {@obj.menuSolverOptions,i};
                uimenu(hMenuO,'Label',mStrO{i},'Callback',cbFcnO,...
                              'Tag',sprintf('%s%i',obj.mStr0,i));
            end
            
            % creates the training parameter menu items
            uimenu(obj.hMenuP,'Label','Training Parameters',...
                              'Callback',@obj.menuTrainPara);

            % ------------------------------- %                      
            % --- HOUSE-KEEPING EXERCISES --- %
            % ------------------------------- %                      
            
            % sets the use existing model menu item properties
            if isempty(obj.pCNN)
                obj.setMenuItemProps(false);
            else
                obj.setMenuItemProps(~isempty(obj.pCNN.pNet));
            end
            
            % resets the menu item
            tStrC = sprintf('%s%i',obj.mStr0,obj.sTypeCNN);
            obj.resetMenuCheck(obj.getMenuItem(tStrC));            
            
        end        
        
        % -------------------------- %
        % --- CALLBACK FUNCTIONS --- %
        % -------------------------- %
        
        % --- load network model callback function        
        function menuLoadModel(obj, ~, ~)
            
            % prompts the user for the network model file
            [fName,fDir,fIndex] = uigetfile(obj.fMode,obj.tStrL,obj.dDir);
            if fIndex == 0
                % if the user cancelled, then exit
                return
            end
            
            % loads the network model file
            fFile = fullfile(fDir,fName);
            obj.pCNN = importdata(fFile,'mat');
            
            % enables the menu items and appends the classfied image field
            obj.setMenuItemProps(1);
            obj.objB.appendClassiferImage(1);
            
            % prompts the user if they want to use model straight away
            if obj.sTypeCNN > 1
                % prompts the user
                tStr = 'Update Classification Options';
                qStr = ['Do you want to update the classification ',...
                        'options to use this model?'];
                uChoice = questdlg(qStr,tStr,'Yes','No','Yes');
                
                % resets the checkmark if required
                if strcmp(uChoice,'Yes')
                    % resets the solver type flag
                    obj.sTypeCNN = 1;
                    obj.resetMenuCheck(obj.getMenuItem([obj.mStr0,'1']));            
                end
            end
            
        end
        
        % --- save network model callback function        
        function menuSaveModel(obj, ~, ~)        
           
            % prompts the user for the network model file
            [fName,fDir,fIndex] = uiputfile(obj.fMode,obj.tStrS,obj.dDir);
            if fIndex == 0
                % if the user cancelled, then exit
                return
            end
            
            % saves the network model file
            pCNN = obj.pCNN;
            fFile = fullfile(fDir,fName);
            save(fFile,'pCNN');
            
        end
            
        % --- solver options callback function
        function menuSolverOptions(obj, hMenu, ~, sTypeNw)
           
            % resets the solver type flag
            obj.sTypeCNN = sTypeNw;
            
            % resets the menu-item checkmark
            obj.resetMenuCheck(hMenu);            
            
        end
        
        % --- network training parameters callback function
        function menuTrainPara(obj, ~, ~)
           
            BlobCNNParaDialog(obj.objB);
            
        end        
        
        % ------------------------------- %
        % --- MISCELLANEOUS FUNCTIONS --- %
        % ------------------------------- %
        
        % --- retrieves the menu item with the tag string, tStr
        function hMenu = getMenuItem(obj,tStr)
            
            hMenu = findall(obj.hFig,'tag',tStr);
            
        end        
        
        % --- sets the menu enabled properties
        function setMenuEnable(obj,tStr,eState)
        
            setObjEnable(obj.getMenuItem(tStr),eState);
            
        end
        
        % --- sets the menu item enabled properties
        function setMenuItemProps(obj,hasModel)
            
            obj.setMenuEnable('hSave',hasModel);
            obj.setMenuEnable([obj.mStr0,'1'],hasModel);
            
        end  
        
        % --- resets the class option
        function resetClassOptCheck(obj)
            
            % resets the classifier option menu item check
            mStrC = sprintf('%s%i',obj.mStr0,obj.sTypeCNN);
            obj.resetMenuCheck(obj.getMenuItem(mStrC));
            
            % sets the menu item properties
            hasModel = ~(isempty(obj.pCNN) || isempty(obj.pCNN.pNet));
            obj.setMenuItemProps(hasModel);
            
        end
        
    end
    
    % static class methods
    methods (Static)
                
        % --- resets the menu check item
        function resetMenuCheck(hMenuC)
            
            % resets the currently selected menu item
            hMenuPr = findall(get(hMenuC,'Parent'),'Checked','On');
            if ~isempty(hMenuPr)
                set(hMenuPr,'Checked','off');
            end
            
            % sets the menu item checkmark
            set(hMenuC,'Checked','on');
            
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