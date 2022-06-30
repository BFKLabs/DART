% --- plots the SEM range patch for a signal, Ysig, with SEM range Ysem. if
%     a 2D array is provided for Ysem, then the 1st/2nd columns are the
%     lower/upper bound respectively. the SEM range is set for the time
%     values, Xsig, and has colour/face alpha
function plotSignalSEM(Ysig,Ysem,Xsig,col,fAlpha)

% %
% [ii,ii2] = deal(isnan(Ysig),isnan(Ysem));
% if (all(ii) || all(ii2))
%     return
% elseif (any(ii))    
%     jj = find(~ii); ii = find(ii);
%     Ysig(ii) = interp1(jj,Ysig(jj),ii);
%     Ysem(ii) = interp1(jj,Ysem(jj),ii);
% end
% 
% %
% kk = false(length(ii),1);
% kk(find(~ii2,1,'first'):find(~ii2,1,'last')) = true;
% [Ysig(~kk),Ysem(~kk)] = deal(NaN);
% kk = find(kk)';

% --- input argument setting --- %

% determines the non-NaN sections of the curve
iGrp = getGroupIndex(~isnan(Ysig));

% sets the input arguments (for those not provided)
if (nargin < 3); Xsig = 1:length(Ysig); end
if (nargin < 4); col = 'b'; end
if (nargin < 5); fAlpha = 0.3; elseif (isnan(fAlpha)); fAlpha = 0.3; end
if (isempty(Xsig)); Xsig = (1:length(Ysig))'; end

% % interpolates the signal values for those that are missing
% for i = 1:size(Ysem,2)
%     ii = isnan(Ysem(kk,i));
%     if (~all(ii))
%         [xiN,xiP] = deal(find(~ii),find(ii));
%         if (~isempty(xiP))
%             Ysem(kk(xiP),i) = interp1(Xsig(kk(xiN)),Ysem(kk(xiN),i),Xsig(kk(xiP)),'linear','extrap');
%         end
%     end
% end

% retrieves the current axes handle
hAx = getCurrentAxesProp;

% creates the fill objects for each non-NaN group
hold on;
for i = 1:length(iGrp)
    % retrieves the indices for the current non-NaN group
    kk = iGrp{i};

    % sets the signal upper/lower limits
    XsigNw = Xsig(kk);
    if iscell(Ysem)
        [YL,YU] = deal(Ysem{1}(kk),Ysem{2}(kk));        
    elseif (size(Ysem,2) == 1)
        [YL,YU] = deal(Ysig(kk)-Ysem(kk),Ysig(kk)+Ysem(kk));
    else
        [YL,YU] = deal(Ysem(kk,1),Ysem(kk,2));
    end

    % sets the fill object x/y locations
    [xFill,yFill] = deal([XsigNw;XsigNw(end:-1:1)],[YL;YU(end:-1:1)]);

    % creates the fill object    
    hFill = fill(xFill,yFill,col,'facealpha',fAlpha,'linestyle','none');
    set(hFill,'parent',hAx)
end