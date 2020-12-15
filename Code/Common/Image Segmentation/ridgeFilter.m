function rMat = ridgeFilter(im, w, outPhase)
%function rMat = ridgefilter(im, w, outPhase)
% This function impliments the ridge detector described papers by
% Meijering et al. This is based on convolving the image with
% steerable filters formed from second order derivatives of Gaussians.
%
%	im - image matrix (doubles between 0 and 1)
%	w - characteristic width of Gaussian
%
% Note that this version has been modified to simply ignore pixels
% that yield complex eigenvalues.

% sets the default input arguments
if (nargin < 2); w = 3; end
if (nargin < 3); outPhase = false; end

% Construct second order derivs of Gaussian
ghalfw = 10;
[X,Y]=meshgrid(-ghalfw:ghalfw);

%
Gxx = (2/(pi*w^2))*((2/w)*X.^2 - 1).*exp(-(X.^2 + Y.^2)/w);
Gxy = (4/(pi*w^3))*X.*Y.*exp(-(X.^2+Y.^2)/w);
Gyy = (2/(pi*w^2))*((2/w)*Y.^2 - 1).*exp(-(X.^2 + Y.^2)/w);

% Filter input:
fxx = conv2(im,Gxx,'same');
fxy = conv2(im,Gxy,'same');
fyy = conv2(im,Gyy,'same');

% Construct modified Hessian matrix of filtered input:
alpha = -1/3; % See Meijering et al., Cyt. A 58A, 167 (2004)
Ha = reshape(fxx + alpha*fyy,numel(fxx),1);
Hb = reshape((1-alpha)*fxy,numel(fxx),1);
Hd = reshape(fyy + alpha*fxx,numel(fxx),1);

% Pays to be careful:
if min((Ha - Hd).^2 + 4*Hb.^2) < 0
    fprintf(1,'Error: Hessian matrix will generate imaginary eigenvalues!\n');
    return
end

% Compute (smallest) eigenvalues:
p = 0.5*(Ha+Hd);
q = 0.5*sqrt((Ha - Hd).^2 + 4*Hb.^2);
l1 = p - q;

% Resize eigenangle and eigenvalue matrices:
l1 = reshape(l1,size(fxx));
rho = (l1./min(min(l1))).*(l1<0);

% Assemble rMat:
rMat = zeros(size(fxx,1),size(fxx,2),1+outPhase);
rMat(:,:,1) = rho;

% Compute corresponding eigenvectors:
if (outPhase)
    z1 = Hb - sqrt(-1)*(Ha-l1);
    theta1 = mod(2*pi+angle(z1),pi)-pi/2;
    theta1 = reshape(theta1,size(fxx));
    rMat(:,:,2) = theta1;
end

% Zero rho near boundary:
rMat(1:ghalfw,:) = 0;
rMat((size(fxx,1)-ghalfw):size(fxx,1),:) = 0;
rMat(:,1:ghalfw) = 0;
rMat(:,(size(fxx,2)-ghalfw):size(fxx,2)) = 0;

