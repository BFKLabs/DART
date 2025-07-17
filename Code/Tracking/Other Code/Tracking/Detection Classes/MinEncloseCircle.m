classdef MinEncloseCircle
    
    % class properties
    properties
        
        % main class fields
        cP
        
    end
    
    % class methods
    methods
        
        % --- class constructor
        function obj = MinEncloseCircle(P)         
            
            % runs the welzl algorithm
            obj.cP = obj.runWelzlAlgo(P,[]);
            
        end
        
        % --- runs the recursive welzl algorithm
        function cPara = runWelzlAlgo(obj,P,R)
            
            % base case (all points are processed or length(R) == 3)
            if (size(P,1) == 0) || (size(R,1) == 3)
                cPara = obj.minCirclePara(R);
                
            else
                % determines the new comparison point
                iNw = randi([1,size(P,1)]);
                pNw = P(iNw,:);
                
                % removes the row from the array
                P = P(~setGroup(iNw,[size(P,1),1]),:);

                % determines if the new point is within the min circle
                cPara = obj.runWelzlAlgo(P,R);
                if ~obj.insideCircle(cPara,pNw)
                    % if not, then add the new boundary point
                    R = [R;pNw];
                    cPara = obj.runWelzlAlgo(P,R);
                end
            end            
            
        end                
        
        %
        function cPara = minCirclePara(obj,R)
            
            switch size(R,1)
                case 0
                    % case is there are no points
                    cPara = struct('pC',[0,0],'R',0);
                
                case 1
                    % case is there is one point
                    cPara = struct('pC',R,'R',0);
                    
                otherwise
                    % case is there are <= 3 points
                    cPara = obj.calcCirclePara(R);
                    
                    if isinf(cPara.R)
                        a = 1;
                    end
            end
                    
        end       
           
        % --- calculates the circle parameters from the points p0-p2
        function cPara = calcCirclePara(obj,R)
        
            if size(R,1) == 3
                % case is 3 point are given
                p0 = R(1,:);
                pC0 = obj.calcCircleCentre(R(2,:)-p0,R(3,:)-p0);
                cPara = struct('pC',pC0+p0,'R',pdist2(pC0,p0)/2);
                
            else
                % case is only 2 points are given
                cPara = struct('pC',mean(R,1)/2,...
                               'R',pdist2(R(1,:),R(2,:))/2);
            end
            
        end                
        
    end
    
    %
    methods (Static)
        
        function pC = calcCircleCentre(p0,p1)
            
            % precalculations
            b = sum(p0.^2);
            c = sum(p1.^2);
            d = p0(1)*p1(2) - p0(2)*p1(1);
            
            % circle centre calculation 
            pC = [(p1(2)*b - p0(2)*c),(p0(1)*c - p1(1)*b)]/(2*d);
                        
        end
        
        function isIn = insideCircle(cPara,p)
            
            isIn = pdist2(cPara.pC,p) <= cPara.R;
            
        end        
        
        % --- swaps the position of the rows in the points array
        function P = swapPoints(P,i0,i1)
           
            [P(i0,:),P(i1,:)] = deal(P(i0,:),P(i1,:));
            
        end        
        
    end
    
end