classdef SingleTrackFull < TrackFull & SingleTrack

    % class methods
    methods 
        
        % class constructor
        function obj = SingleTrackFull(iData)
            
            % creates the super-class object
            obj@TrackFull(iData,false);
            obj@SingleTrack(iData);
            
            % sets the class fields
            obj.sObj = obj; 
   
        end
        
        % ------------------------------------- %
        % --- FULL VIDEO TRACKING FUNCTIONS --- %
        % ------------------------------------- %
        
        % --- segments the locations for all flies within the entire video
        function segEntireVideo(obj,hGUI,iMov,pData)
            
            % sets the class object fields
            obj.hGUI = hGUI;
            obj.iMov = iMov;
            obj.pData = pData;
            obj.hFig = hGUI.output;        
            
            % starts the video tracking
            obj.segEntireVideoFull();
            if ~obj.calcOK
                % exit if the user cancelled
                return
            end            
            
            % solution diagnostic checks
            if obj.calcOK
                % ensures the tracking efficacy is correct
                obj.checkFinalSegSolnF();                                 
                if obj.calcOK
                    % if orientation angles are calculated, then convert 
                    % them from the [-pi/2,pi/2] range to [-pi,pi]
                    if obj.pData.calcPhi
                        obj.convertAllOrientationAnglesF();
                    end                    
                    
                    % updates the solution tracking GUI
                    obj.updateTrackingGUI(); 
                end
            end
            
            % closes the waitbar figure (single segmentation only)
            if ~obj.isBatch
                obj.hProg.closeProgBar();
            end

        end        
        
        % -------------------------------------------- %
        % ---- TRACKING POST-PROCESSING FUNCTIONS ---- %
        % -------------------------------------------- %        
        
        % --- checks the final solution for any anomalies
        function checkFinalSegSolnF(obj)
            
            % updates the global variables
            global wOfs
            wOfs = obj.wOfs1 - 1;
           
            % runs the final segmentation check function
            [obj.pData,obj.iMov,obj.calcOK] = checkFinalSegSoln(obj);
            
            % runs the hi-variance phase segmentation
            if obj.calcOK
                obj.segHiVarPhase();  
                
                % updates the main GUI fields
                set(obj.hFig,'iMov',obj.iMov)
                set(obj.hFig,'pData',obj.pData)                
            end                        
            
        end
           
        % --- converts all the final orientation angles
        function convertAllOrientationAnglesF(obj)
            
            % updates the global variables
            global wOfs
            wOfs = obj.wOfs1;            
            
            % runs the orientation angle conversion function
            [obj.pData,obj.calcOK] = convertAllOrientationAngles(...
                                obj.pData,obj.iData,obj.iMov,obj.hProg);
            
        end                
        
        % --- segments the high variance phases
        function segHiVarPhase(obj)
            
            % --- sets up the interpolation objects
            function [pX,pY] = setupInterpObj(Tint,fPos)

                pX = pchip(Tint,fPos(:,1));
                pY = pchip(Tint,fPos(:,2));

            end

            % if there are no high variance phases, then exit the function            
            ii = obj.iMov.vPhase == 3;
            if ~any(ii)
                return
            end
            
            % initialisations
            T = obj.pData.T;
            iPh = obj.iMov.iPhase;
            iGrp = getGroupIndex(ii);
            
            % determines the interpolation (non-NaN) frames
            i0 = find(obj.iMov.ok,1,'first');
            j0 = find(obj.iMov.flyok(:,i0),1,'first');
            intFrm = ~isnan(obj.pData.fPos{i0}{j0}(:,1));                    
            
            % determines if there are any valid groups for interpolation
            % (first frame > 1 and last frame < nFrm)
            isOK = cellfun(@(x)((iPh(x(1),1)>1) && ...
                                    (iPh(x(end),2)<obj.iData.nFrm)),iGrp);
            if ~any(isOK)
                % if not, then exit the function
                return
            else
                % otherwise, set the interpolation time and feasible phases
                [Tint,iGrp] = deal(T(intFrm),iGrp(isOK));
            end
            
            % sets the frame indices for the hi-variance phases
            iFrm = cellfun(@(x)(iPh(x(1),1):iPh(x(end),2)),iGrp,'un',0);
            
            % re-segments the high-variance phases
            for iApp = 1:obj.nApp
                for iT = 1:obj.nTube(iApp)
                    if obj.iMov.flyok(iT,iApp)   
                        % sets up the interpolation objects
                        fPos = obj.pData.fPos{iApp}{iT}(intFrm,:);
                        [pX,pY] = setupInterpObj(Tint,fPos); 
                        
                        % sets up the interpolation objects
                        fPosL = obj.pData.fPosL{iApp}{iT}(intFrm,:);
                        [pXL,pYL] = setupInterpObj(Tint,fPosL);                          
                        
                        % interpolates the missing coordinates
                        for i = 1:length(iFrm)
                            % sets the phase time
                            Tph = T(iFrm{i});
                            
                            % interpolates the region coordinates                            
                            pXY = [ppval(pX,Tph),ppval(pY,Tph)];
                            obj.pData.fPos{iApp}{iT}(iFrm{i},:) = pXY;
                            
                            % interpolates the local coordinates 
                            pXYL = [ppval(pXL,Tph),ppval(pYL,Tph)];
                            obj.pData.fPosL{iApp}{iT}(iFrm{i},:) = pXYL;
                        end
                    end
                end
            end            
            
        end               
      
        % ---------------------------------------------------- %            
        % ---- CLASS/DATA STRUCT INITIALISATION FUNCTIONS ---- %
        % ---------------------------------------------------- %                
        
        % --- retrieves the previous phase information
        function prData = setupPrevPhaseData(obj,iFrmLast,varargin)
            
            % memory allocation
            prData = struct('Img',[],'iStatus',[],'IPosPr',[],...
                            'fPos',[],'fPosPr',[]);
            
            % sets the data fields
            prData.Img = obj.getImageStack(iFrmLast,1);
            prData.iStatus = obj.iMov.Status;            
            prData.fPos = cell(obj.nApp,1); 
            prData.IPosPr = cell(obj.nApp,1); 
            
            % sets the previous data locations from the last valid frame  
            dX = cellfun(@(x)(x(1)-1),obj.iMov.iC);
            for iApp = 1:obj.nApp
                pOfs = repmat([dX(iApp),0],obj.nTube(iApp),1);
                prData.fPos{iApp} = cell2mat(cellfun(@(x)...
                    (x(iFrmLast,:)),obj.pData.fPos{iApp}','un',0)) - pOfs;                
            end
            
            % sets the previous frame points (for the extrapolation search)
            indT = max(1,iFrmLast-(obj.nFrmPr-1)):iFrmLast;
            prData.fPosPr = cellfun(@(y)(cellfun(@(x)...
                        (x(indT,:)),y,'un',0)),obj.pData.fPosL,'un',0);            
            prData.IPosPr = cellfun(@(y)(cellfun(@(x)...
                        (x(iFrmLast)),y(:))),obj.pData.IPos,'un',0);
                    
        end
        
        % --- sets up the position data struct
        function [pData,A,B] = setupPosDataStruct(obj,nFrm)
            
            % memory allocation 
            xiT = num2cell(obj.nTube)';

            % sets the fly location data struct
            pData = struct('T',[],'IPos',[],'fPos',[],'fPosL',[],...
                       'isSeg',[],'nTube',obj.nTube,'nApp',obj.nApp,...
                       'nCount',[],'calcPhi',obj.iMov.calcPhi,'frmOK',[]);   
                       
            % sets the positional/orientation angle arrays
            A = cellfun(@(x)(repmat({NaN(sum(nFrm),2)},1,x)),xiT,'un',0);
            B = cellfun(@(x)(repmat({NaN(sum(nFrm),1)},1,x)),xiT,'un',0);            
            
        end        
        
        % --- retrieves the sub-region count
        function nRegion = getSubRegionCount(obj,iApp)

            nRegion = obj.nTube(iApp);

        end                
        
    end 
    
end
