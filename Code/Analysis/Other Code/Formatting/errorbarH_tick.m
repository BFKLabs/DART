function errorbarH_tick(h,w,xtype)

% Check numbers of arguments
narginchk(1,3)

% Check for the use of V6 flag ( even if it is depreciated ;) )
flagtype = get(h,'type');

% Check number of arguments and provide missing values
if nargin==1
	w = 80;
end

if nargin<3
   xtype = 'ratio';
end

% Calculate width of error bars
if ~strcmpi(xtype,'units')
    dy = diff(get(gca,'YLim'));	% Retrieve x limits from current axis
    w = dy/w;                   % Errorbar width
end

% Plot error bars
if strcmpi(flagtype,'hggroup') % ERRORBAR(...)
    
    hh=get(h,'children');		% Retrieve info from errorbar plot
    y = get(hh(2),'ydata');		% Get xdata from errorbar plot
    
    y(4:9:end) = y(1:9:end)-w/2;	% Change xdata with respect to ratio
    y(7:9:end) = y(1:9:end)-w/2;
    y(5:9:end) = y(1:9:end)+w/2;
    y(8:9:end) = y(1:9:end)+w/2;

    set(hh(2),'ydata',y(:))	% Change error bars on the figure

else  % ERRORBAR('V6',...)
    
    y = get(h(1),'ydata');		% Get xdata from errorbar plot
    
    y(2:9:end) = y(4:9:end)-w/2;	% Change xdata with respect to the chosen ratio
    y(7:9:end) = y(4:9:end)-w/2;
    y(1:9:end) = y(4:9:end)+w/2;
    y(8:9:end) = y(4:9:end)+w/2;

    set(h(1),'ydata',y(:))	% Change error bars on the figure
    
end
