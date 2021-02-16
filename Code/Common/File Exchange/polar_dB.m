%************************************************************************
%       polar_dB(theta,rho,rmin,rmax,rticks,line_style)
%************************************************************************
%	POLAR_DB is a MATLAB function that plots 2-D patterns in
%	polar coordinates where:
%		   0      <= THETA (in degrees) <= 360
%		-infinity <  RHO   (in dB)      <  +infinity
%
%	Input Parameters Description
%	----------------------------
%	- theta (in degrees) must be a row vector from 0 to 360 degrees
%	- rho (in dB) must be a row vector
%	- rmin (in dB) sets the minimum limit of the plot (e.g., -60 dB)
%	- rmax (in dB) sets the maximum limit of the plot (e.g.,   0 dB)
%	- rticks is the # of radial ticks (or circles) desired. (e.g., 4)
%	- linestyle is solid (e.g., '-') or dashed (e.g., '--')
%*************************************************************************
%	Credits:
%		S. Bellofiore
%		S. Georgakopoulos
%		A. C. Polycarpou
%		C. Wangsvick
%		C. Bishop
%
%	Tabulate your data accordingly, and call polar_dB to provide the
%	2-D polar plot
%
%	Note:  This function is different from the polar.m (provided by
%	       MATLAB) because RHO is given in dB, and it can be negative
%-----------------------------------------------------------------------------

function hpol = polar_dB(theta,rho,rmin,rmax,rticks)

% Convert degrees into radians
% theta = theta * pi/180;

% Font size, font style and line width parameters
font_size  = 16;
font_name  = 'Times';
lWid = 0.5;

if nargin < 5
    error('Requires 5 or 6 input arguments.')
elseif nargin == 5
    if isstr(rho)
        rho = theta;
        [mr,nr] = size(rho);
        if mr == 1
            theta = 1:nr;
        else
            th = (1:mr)';
            theta = th(:,ones(1,nr));
        end
    end
elseif nargin == 1
    rho = theta;
    [mr,nr] = size(rho);
    if mr == 1
        theta = 1:nr;
    else
        th = (1:mr)';
        theta = th(:,ones(1,nr));
    end
end

% get hold state
cax = newplot;
next = lower(get(cax,'NextPlot'));
hold_state = ishold;

% get x-axis text color so grid is in same color
tc = get(cax,'xcolor');

% Hold on to current Text defaults, reset them to the
% Axes' font attributes so tick marks use them.
fAngle  = get(cax, 'DefaultTextFontAngle');
fSize   = get(cax, 'DefaultTextFontSize');
fWeight = get(cax, 'DefaultTextFontWeight');
set(cax, 'DefaultTextFontAngle', get(cax, 'FontAngle'), ...
    'DefaultTextFontName',   font_name, ...
    'DefaultTextFontSize',   font_size, ...
    'DefaultTextFontWeight', get(cax, 'FontWeight') )

% only do grids if hold is off
if ~hold_state
    
    % make a radial grid
    hold on;
    % v returns the axis limits
    % changed the following line to let the y limits become negative
    hhh=plot([0 max(theta(:))],[min(rho(:)) max(rho(:))]);
    v = [get(cax,'xlim') get(cax,'ylim')];
    ticks = length(get(cax,'ytick'));
    delete(hhh);
    
    % check radial limits (rticks)
    
    %  	if rticks > 5   % see if we can reduce the number
    %  		if rem(rticks,2) == 0
    %  			rticks = rticks/2;
    %  		elseif rem(rticks,3) == 0
    %  			rticks = rticks/3;
    %  		end
    %  	end
    
    % define a circle
    th = 0:pi/50:2*pi;
    xunit = cos(th);
    yunit = sin(th);
    % now really force points on x/y axes to lie on them exactly
    inds = [1:(length(th)-1)/4:length(th)];
    xunits(inds(2:2:4)) = zeros(2,1);
    yunits(inds(1:2:5)) = zeros(3,1);
    
    rinc = (rmax-rmin)/rticks;
    
    % label r
    % change the following line so that the unit circle is not multiplied
    % by a negative number.  Ditto for the text locations.
    for i=(rmin+rinc):rinc:rmax
        is = i - rmin;
        if (i == rmax)
            plot(xunit*is,yunit*is,'-','color',tc,'linewidth',0.5);
        else
            plot(xunit*is,yunit*is,':','color',tc,'linewidth',0.5);
        end
        % 		text(0,is+rinc/20,['  ' num2str(i)],'verticalalignment','bottom' );
    end
    % plot spokes
    th = (1:2)*2*pi/4;
    cst = cos(th); snt = sin(th);
    cs = [-cst; cst];
    sn = [-snt; snt];
    % 	plot((rmax-rmin)*cs,(rmax-rmin)*sn,'-','color',tc,'linewidth',0.5);
    
    % plot the ticks
    % 	george=(rmax-rmin)/30; % Length of the ticks
    %         th2 = (0:36)*2*pi/72;
    %         cst2 = cos(th2); snt2 = sin(th2);
    % 	cs2 = [(rmax-rmin-george)*cst2; (rmax-rmin)*cst2];
    % 	sn2 = [(rmax-rmin-george)*snt2; (rmax-rmin)*snt2];
    % 	plot(cs2,sn2,'-','color',tc,'linewidth',0.15); % 0.5
    %         plot(-cs2,-sn2,'-','color',tc,'linewidth',0.15); % 0.5
    
    
    % annotate spokes in degrees
    % Changed the next line to make the spokes long enough
    [rt,N] = deal(1.15*(rmax-rmin),2);
    for i = 1:N
        j = N-i;
        switch (j)
            case (1)
                [dX1,dY1,loc1] = deal(0,-0.025,'0^{o}');
            case (0)
                [dX1,dY1,loc1] = deal(0.05,0,'270^{o}');
        end
        
        switch (i)
            case (1)
                [dX2,dY2,loc2] = deal(0,0.025,'180^{o}');
            case (2)
                [dX2,dY2,loc2] = deal(-0.05,0,'90^{o}');
        end
        
        %
        text((1+dX1)*rt*cst(i),(1+dY1)*rt*snt(i),loc1,'horizontalalignment','center' );
        text(-(1-dX2)*rt*cst(i),-(1-dY2)*rt*snt(i),loc2,'horizontalalignment','center' );
    end
    % set viewto 2-D
    view(0,90);
    
    % set axis limits
    % Changed the next line to scale things properly
    axis((rmax-rmin)*[-1 1 -1.1 1.1]);
end

% Reset defaults.
set(cax, 'DefaultTextFontAngle', fAngle , ...
    'DefaultTextFontName',   font_name, ...
    'DefaultTextFontSize',   fSize, ...
    'DefaultTextFontWeight', fWeight );

% transform data to Cartesian coordinates.
% changed the next line so negative rho are not plotted on the other side
[xx,yy] = deal(zeros(size(theta)));
for i = 1:size(theta,2)
    xx(:,i) = (rho-rmin).*(cos(theta(:,i)+pi/2));
    yy(:,i) = (rho-rmin).*(sin(theta(:,i)+pi/2));
end

% plot data on top of grid
q = plot(xx,yy);

if nargout > 0
    hpol = q;
end
if ~hold_state
    axis('equal');axis('off');
end

set(q,'linewidth',lWid);


% reset hold state
if ~hold_state, set(cax,'NextPlot',next); end
