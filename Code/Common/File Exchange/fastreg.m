function dmn=fastreg(standimage,compimage)
% A very fast subpixel image registration or alignment based on cross correlation
% and modified moment algorithm . Its accuracy is around 0.01-0.1 pixel
% according to the SNR and the size of images.
% Inputs
% standimage: the first image
% compimage:  the second image. It should be the same size as the first image
% Outputs
% m: the shift in X
% n: the shift in Y
% This code is implemented based on the following algorithm. Please cite
% it.
% http://ieeexplore.ieee.org/xpl/articleDetails.jsp?tp=&arnumber=6463241
% Song Min, June, 2013
[M,N]=size(standimage);
standimage=double(standimage);
compimage=double(compimage);
R0=2;
R1=R0+5;
% pixel level registration 
[M0,N0]=regsurf(standimage,compimage);
M0=floor(M0-M/2-1);
N0=floor(N0-N/2-1);
compimage=circshift(compimage,[M0,N0]);
standimage2=standimage(abs(M0)+1:end-abs(M0),abs(N0)+1:end-abs(N0));
compimage2=compimage(abs(M0)+1:end-abs(M0),abs(N0)+1:end-abs(N0));
%subpixel level registration
[M,N]=size(standimage2);
if min(M,N)<500
    w=1;
else
    wm=gausswin(M);
    wn=gausswin(N);
    w=wm(:)*wn(:)';
end
[m,n,im]=regsurf((standimage2.*w),(compimage2.*w));

try
    [x,y]=meshgrid(-R1:R1,-R1:R1);
    immin=min(min(im((m-R0):(m+R0),(n-R0):(n+R0))));
    im=max(im-immin,0);
    im0=im(m-R1:m+R1,n-R1:n+R1);
    area = sum(im0(:));
    n = sum(sum(im0.*x))/area+n;
    m = sum(sum(im0.*y))/area+m;
    
    m=m-M/2-1;
    n=n-N/2-1;
    
    if mod(M,2)
        m=m+0.5;
    end
    if mod(N,2)
        n=n+0.5;
    end
catch
    m=0;
    n=0;
end
dmn=[m+M0,n+N0];

function [m,n,im]=regsurf(standimage,compimage)
s=fft2(standimage);
c=ifft2(compimage);
sc=s.*c;
im=abs(fftshift(ifft2(sc)));
[M0,N0]=find(im==max(im(:)));
m=round(mean(M0));
n=round(mean(N0));