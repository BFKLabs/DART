function [Aout,Eout,Kout] = arburg(x, p)
%ARBURG   AR parameter estimation via Burg method.
%   A = ARBURG(X,ORDER) returns the coefficients of the autoregressive (AR)
%   parametric signal model estimate of X using Burg's method. The model
%   has order ORDER, and the output array A has ORDER+1 columns.  The
%   coefficients along the Nth row of A model the Nth column of X.  If X is
%   a vector then A is a row vector.
%
%   [A,E] = ARBURG(...) returns the final prediction error E (the variance
%   estimate of the white noise input to the AR model).
%
%   [A,E,K] = ARBURG(...) returns the reflection coefficients (parcor
%   coefficients) in each column of K.
%
%   % Example:
%   %   Estimate input noise variance for AR(4) model.
%   A=[1 -2.7607 3.8106 -2.6535 0.9238]; 
%
%   % Generate noise standard deviations
%   % Seed random number generator for reproducible results
%   rng default;
%   noise_stdz=rand(1,50)+0.5;
%
%   % Generate column vectors that have corresponding standard deviation
%   x = bsxfun(@times,noise_stdz,randn(1024,50));
%
%   % filter each column using the AR model.
%   y = filter(1,A,x);
%
%   % Compute the estimated coefficients and deviations for each column
%   [ar_coeffs,NoiseVariance]=arburg(y,4);
%
%   %Display the mean value of each estimated polynomial coefficient
%   estimatedA = mean(ar_coeffs)
%
%   %Compare actual vs. estimated variances
%   plot(noise_stdz.^2,NoiseVariance,'k*');
%   xlabel('Input Noise Variance');
%   ylabel('Estimated Noise Variance');
%
%   See also PBURG, ARMCOV, ARCOV, ARYULE, LPC, PRONY, FILLGAPS.

%   Ref: S. Kay, MODERN SPECTRAL ESTIMATION,
%              Prentice-Hall, 1988, Chapter 7
%        S. Orfanidis, OPTIMUM SIGNAL PROCESSING, 2nd Ed.
%              Macmillan, 1988, Chapter 5

%   Copyright 1988-2014 The MathWorks, Inc.

narginchk(2,2)

% convert to column vector before 2d check is performed
if isvector(x)
  x = x(:);
end

validateattributes(x,{'numeric'},{'nonempty','finite','2d'},'arburg','X');
validateattributes(p,{'numeric'},{'positive','integer','scalar'},'arburg','ORDER');
% Cast to enforce precision rules
p = double(p);
N  = size(x,1);
Nchan = size(x,2);

% By convention all polynomials are row vectors
Aout = zeros(Nchan, p+1, class(x));
% Optional outputs
Eout = zeros(1, Nchan, class(x));
Kout = zeros(p, Nchan, class(x));

for ichan = 1:Nchan
  % Initialization
  efp = x(2:end,ichan);
  ebp = x(1:end-1,ichan);

  % Initial error
  E = x(:,ichan)'*x(:,ichan)./N;

  a = zeros(1,p+1,class(x));
  a(1) = 1;

  for m=1:p
     % Calculate the next order reflection (parcor) coefficient
     k = (-2.*ebp'*efp) ./ (efp'*efp + ebp'*ebp);
     Kout(m,ichan) = k;
     
     % Update the forward and backward prediction errors
     ef = efp(2:end)    + k  .* ebp(2:end);
     ebp = ebp(1:end-1) + k' .* efp(1:end-1);
     efp = ef;

     % Update the AR coeff.
     a(2:m+1) = a(2:m+1) + k .* conj(a(m:-1:1));

     % Update the prediction error
     E = (1 - k'.*k)*E;
  end
  
  % Assign outputs
  Aout(ichan,:) = a;
  Eout(ichan) = E;
end
