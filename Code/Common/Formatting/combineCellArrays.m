% --- combines two cell arrays, A & B, of any size either horizontally or
%     vertically (based on the value of joinHoriz). the resultant array
%     will contain empty cell arrays to make up space
function C = combineCellArrays(A,B,joinHoriz,x)

% flag that the arrays are connected horizontally (if flag not provided)
if (nargin < 3); joinHoriz = true; end
if (nargin < 4); x = NaN; end

% sets the sizes of the arrays
[szA,szB] = deal(size(A),size(B));
[Hmx,Wmx] = deal(max(szA(1),szB(1)),max(szA(2),szB(2)));

% connects the arrays based on their orientations
if joinHoriz
    % horizontal connection
    if ischar(x)
        % sets the final combined array
        C = [[A;repmat({''},Hmx-szA(1),szA(2))],...
             [B;repmat({''},Hmx-szB(1),szB(2))]]; 
        return 
        
    elseif isnan(x)
        [A1,B1] = deal(NaN(Hmx-szA(1),szA(2)),NaN(Hmx-szB(1),szB(2)));   
        
    else
        [A1,B1] = deal(x*ones(Hmx-szA(1),szA(2)),x*ones(Hmx-szB(1),szB(2)));    
    end
    
    % sets the final combined array
    C = [[A;num2cell(A1)],[B;num2cell(B1)]];
else
    % vertical connection
    if ischar(x)
        % sets the final combined array
        C = [[A,repmat({''},szA(1),Wmx-szA(2))];...
             [B,repmat({''},szB(1),Wmx-szB(2))]]; 
        return     
    
    elseif isnan(x)
        [A1,B1] = deal(NaN(szA(1),Wmx-szA(2)),NaN(szB(1),Wmx-szB(2)));
        
    else
        [A1,B1] = deal(x*ones(szA(1),Wmx-szA(2)),x*ones(szB(1),Wmx-szB(2)));
    end
    
    % sets the final combined array
    C = [[A,num2cell(A1)];[B,num2cell(B1)]];
end