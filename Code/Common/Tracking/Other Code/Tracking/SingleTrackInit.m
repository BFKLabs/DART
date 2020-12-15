classdef SingleTrackInit < SingleTrack
    properties
        % parameters
        wOfsL = 0;
    end
    
    methods 
        % class constructor
        function obj = SingleTrackInit(iData)
            
            % creates the super-class object
            obj@SingleTrack(iData);
   
        end
        
        % ----------------------------------------- %
        % --- INITIAL OBJECT ESTIMATE FUNCTIONS --- %
        % ----------------------------------------- %
        
        % --- calculates the initial fly location/background estimates
        function calcInitEstimate(obj,iMov,hProg)
            
            % sets the input variables
            obj.iMov = iMov;
            obj.hProg = hProg;
            
            % other initialisations
            nPhase = length(obj.iMov.vPhase);
            
            % initialises the tracking objects
            obj.initTrackingObjects('InitEstimate'); 
            wStr0 = obj.hProg.wStr;            
            
            % loops through each phase calculating the initial estimates
            for i = 1:nPhase
                % updates the overall progress 
                wStr = sprintf(...
                    'Initial Estimate Progress (Phase %i of %i)',i,nPhase);
                obj.hProg.Update(1+obj.wOfsL,wStr,i/(1+nPhase));
                
                % resets the other progressbar fields (for phases > 1)
                if i > 1
                    for j = obj.wOfsL + (2:3)
                        obj.hProg.Update(j,wStr0{j},0);
                    end
                end
                
                % reads the image stack for phase frame indices
                iFrm = getPhaseFrameIndices(obj.iMov.iPhase(i,:),obj.nFrmR);
                Img = obj.getImageStack(iFrm);       
                
                % sets the class fields for the tracking object
                obj.fObj{i}.setClassField('Img',Img);
                obj.fObj{i}.setClassField('wOfs',1+obj.wOfsL);
                obj.fObj{i}.setClassField('calcBG',obj.iMov.vPhase(i)==1)    
                
                % sets the initial object locations
                if i == 1
                    % case is the first phase (no previous points)
                    prData = [];
                else
                    % case is the sub-sequent phases
                    prData = obj.getPrevPhaseData(obj.fObj{i-1});
                end                
                
                % runs the direct detection algorithm   
                obj.fObj{i}.runDetectionAlgo(prData);
                if ~obj.fObj{i}.calcOK
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end
            end
            
            % updates the progress bar
            obj.hProg.Update(1+obj.wOfsL,'Initial Estimate Complete!',1);            
                
            % sets the background images into the sub-region data struct
            obj.iMov.Ibg = cellfun(@(x)(x.IBG),obj.fObj,'un',0);
            obj.iMov.pBG = cellfun(@(x)(x.pBG),obj.fObj,'un',0);
            
            % sets the status flags for each phase (full and overall)
            obj.iMov.StatusF = cellfun(@(x)(x.iStatus),obj.fObj,'un',0);
            obj.iMov.Status = num2cell(min(cell2mat(...
                        reshape(obj.iMov.StatusF,[1,1,nPhase])),[],3),1);                          
            
        end                          
      
        % --- segments the first frame of each phase (bg estimate only)
        function segFirstPhaseFrame(obj,iMov,ImgPhase)
           
            % sets the input arguments/
            obj.iMov = iMov;
            
            % creates the progress bar
            wStrPB = {'Overall Progress','Sub-Region Segmentation'};
            obj.hProg = ProgBar(wStrPB,'First Phase Frame Segmentation');
            
            % other initialisations
            nPhase = length(ImgPhase);
            
            % initialises the tracking objects
            obj.initTrackingObjects('Detect'); 
            
            % calculates the object locations for each phase
            for i = 1:nPhase
                % updates the overall progress
                wStrNw = sprintf('Overall Progress (%i of %i)',i,nPhase);
                obj.hProg.Update(1,wStrNw,i/nPhase);
                
                % sets the class fields for the tracking object                
                obj.fObj{i}.setClassField('wOfs',1+obj.wOfsL);
                obj.fObj{i}.setClassField('iPhase',i);
                obj.fObj{i}.setClassField('Img',{ImgPhase{i}});
                
                % runs the detection algorithm for the tracking object
                obj.fObj{i}.runDetectionAlgo([]);
                    
                if ~obj.fObj{i}.calcOK
                    % if the user cancelled, then exit the function
                    obj.calcOK = false;
                    return
                end                
            end
            
            % closes the progress bar
            obj.hProg.closeProgBar();
            
        end             
    end
end