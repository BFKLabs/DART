% --- creates a figure plot for a range of different graphs
function varargout = plotGraph(pType,varargin)

% creates a new figure
try
    h = varargin{2};
    subplot(h)
catch exception
    if (~isempty(exception.message))
        sz = get(0,'ScreenSize');
%         h = figure('position',[sz(1) sz(2)+sz(3)/2 sz(3)/4 sz(4)/2]);
        if prod(sz(3:4) < 10)
            h = figure('position',[100 100 700 500]);            
        else
            h = figure('position',[sz(1) sz(2)+sz(4)/2-100 sz(3)/2 sz(4)/2]);
        end
    end
end

% sets the input arguments into a cell array
p = varargin;
vout = {};

% selects the graph to draw based on pType
switch (pType)
    case ('image') % case is showing the image 
        showImage(p)    
    case ('movie') % case is showing the movie
        switch (length(p))
            case (1)
                showMovie(p) 
            case (2)
                showMovie(p(1),p{2}) 
            otherwise
                pp = p([1 3:length(p)]);
                if (isempty(p{2}))
                    showMovie(pp)     
                else
                    showMovie(pp,p{2}) 
                end
        end
    case ('moviesel')
        switch (length(p))
            case (1)
                I = p{1};
        end

        % 
        showImage(I{1})
        setappdata(h,'I',I);      
        setappdata(h,'cFrm',1);
        set(h,'WindowKeyPressFcn',@KeyPressCallback);
        title(sprintf('Frame %i of %i',1,length(I)));
end

% 
if (~isempty(vout))
    for i = 1:length(vout)
        varargout(i) = {vout{i}};
    end
end

%-------------------------------------------------------------------------%
%                          FIGURE PLOT FUNCTIONS                          % 
%-------------------------------------------------------------------------%

% --- 
function KeyPressCallback(hObject,eventdata)

%
I = getappdata(hObject,'I');
cFrm = getappdata(hObject,'cFrm');

%
if (isempty(eventdata.Modifier))
    Modifier = 'None';
else
    Modifier = 'eventdata.Modifier';
end

%
switch (eventdata.Key)
    case ('rightarrow') % case is the right arrow
        if (cFrm ~= length(I))
            if (strcmp(Modifier,'control'))
                cFrm = min(cFrm + 5,length(I));
            else
                cFrm = cFrm + 1;
            end
        else
            return
        end
    case ('leftarrow') % case is the left arrow
        if (cFrm ~= 1)
            if (strcmp(Modifier,'control'))
                cFrm = max(cFrm - 5,1);
            else
                cFrm = cFrm - 1;
            end
        else
            return
        end        
    otherwise % other keys
        return
end

%
hImage = findobj(hObject,'Type','Image');
set(hImage,'cData',I{cFrm});
if (~isempty(I{cFrm}))
    axis([1 size(I{cFrm},2) 1 size(I{cFrm},1)])
else
    axis([1 2 1 2])
end

%
title(sprintf('Frame %i of %i',cFrm,length(I)));
setappdata(hObject,'cFrm',cFrm);

% --- shows the scaled image
function showImage(p)
% I         image pixel intensity

% sets the image data
if (iscell(p))
    img = p{1};
else
    img = p;
end

% plots the image
hImage = findobj(gca,'type','image');
if (isempty(hImage))
    if (size(img,3) == 1)
        imagesc(img); 
        colormap(gray);    
    else
        image(uint8(img))
    end

    %
    set(gca,'xticklabel',[],'yticklabel',[],'xtick',[],'ytick',[]);
else
    %
    if (size(img,3) == 1)
        set(hImage,'cdata',img);   
    else
        set(hImage,'cdata',uint8(img));   
    end
end

%
axis image    

% --- shows the movie stack
function showMovie(p,hAx)

%
if (nargin == 1)
    hAx = subplot(1,1,1);
end

%
if (iscell(p{1}))
    %
    ImgStack = p{1};
    
    %
    switch (length(p))
        case (1)
            ind = 1:length(ImgStack);
            tPause = 0.1;
        case (2) 
            ind = p{2};
            tPause = 0.1;
        case (3)
            ind = p{2};
            tPause = p{3};
    end
else
    %
    ImgStack = field2cell(p{1},p{2});
    
    %
    switch (length(p))
        case (2)
            ind = 1:length(ImgStack);
            tPause = 0.1;
        case (3) 
            ind = p{3};
            tPause = 0.1;
        case (4)
            ind = p{3};
            tPause = p{4};
    end 
end

% intialisations
nFrm = length(ind);

% loops through all the image stack showing all the images
for j = 1:nFrm
    % sets the current image frame
    i = ind(j);
    
    % updates the figure axis and title for the current frames
    if (~isempty(ImgStack{i}))
        plotGraph('image',ImgStack{i},hAx);
        title(sprintf('Frame %i of %i',i,length(ImgStack)));
    end
    
    % pauses the frame for update
    pause(tPause);
end