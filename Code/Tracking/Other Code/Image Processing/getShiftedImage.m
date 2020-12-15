% --- shifts the image stack, I by the distance dX/dY in the X/Y direction
function Inw = getShiftedImage(I,dX,dY)

% sets the coarse/fine x/y shift values
[dXc,dXf] = deal(sign(dX)*floor(abs(dX)),sign(dX)*mod(abs(dX),1));
[dYc,dYf] = deal(sign(dY)*floor(abs(dY)),sign(dY)*mod(abs(dY),1));

% ensures the sub-pixel shift values are positive
if (dXf < 0); [dXc,dXf] = deal(dXc-1,dXf+1); end
if (dYf < 0); [dYc,dYf] = deal(dYc-1,dYf+1); end

% retrieves the image size
ImgSz = size(I);    
if (length(ImgSz) == 2)
    % if not a true colour image, then add a 3rd dimension
    ImgSz = [ImgSz 1];
end

% calculates the coarse shift (if there is a non-zero shift)
if (dXc == 0) && (dYc == 0)
    % no shift, so shifted is the same as original 
    Inw = I;
else
    % sets the new row/column indices
    Inw = NaN(ImgSz);
    iR0 = max(1,1+dYc):min(ImgSz(1),ImgSz(1)+dYc);
    iR1 = max(1,1-dYc):min(ImgSz(1),ImgSz(1)-dYc);
    iC0 = max(1,1+dXc):min(ImgSz(2),ImgSz(2)+dXc);
    iC1 = max(1,1-dXc):min(ImgSz(2),ImgSz(2)-dXc);

    % shifts the images by the amount specified
    for i = 1:ImgSz(3)
        Inw(iR1,iC1,i) = I(iR0,iC0,i);              
    end
end

% calculates the fine shift (if there is a non-zero shift)
if ((dXf ~= 0) || (dYf ~= 0))
    for i = 1:ImgSz(3)
        Inw(:,:,i) = conv2(Inw(:,:,i),[dYf; 1-dYf]*[dXf, 1-dXf],'same');
        if (dYf > 0); Inw(end,:,i) = NaN; end
        if (dXf > 0); Inw(:,end,i) = NaN; end
    end
end    