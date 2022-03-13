% --- calculates the intersection coordinates of 2 ellipses, E1 and E2
function pT = calcEllipseIntersectCoords(E1,E2)

% sets the ellipse parameters from the data struct
[p1,p2] = deal(E1.theta,E2.theta);
[h1,k1,h2,k2] = deal(E1.x,E1.y,E2.x,E2.y);
[A1,B1,A2,B2] = deal(E1.l,E1.w,E2.l,E2.w);
[c1,s1,p2R] = deal(cos(p1),sin(p1),p2-p1);

% calculates the rotated horizontal/vertical offsets
h2_tr = (h2-h1)*c1 + (k2-k1)*s1;
k2_tr = (h1-h2)*s1 + (k2-k1)*c1;

% calculates the rotated/translated parameters
[c2R,s2R] = deal(cos(p2R),sin(p2R));
[c2R2,s2R2,cs2R] = deal(c2R*c2R,s2R*s2R,2*c2R*s2R);

% calculates the temporary variable values
[A22,B22] = deal(A2*A2,B2*B2);
T0 = (c2R*h2_tr + s2R*k2_tr)/A22;
T1 = (s2R*h2_tr - c2R*k2_tr)/B22;
T2 = c2R*h2_tr + s2R*k2_tr;
T3 = s2R*h2_tr - c2R*k2_tr;

% implicit polynomial coefficients for the 2nd ellipse
AA = c2R2/A22 + s2R2/B22;
BB = cs2R*(1/A22 - 1/B22);
CC = s2R2/A22 + c2R2/B22;
DD = -2*c2R*T0 - 2*s2R*T1;
EE = -2*s2R*T0 + 2*c2R*T1;
FF = (T2^2)/A22 + (T3^2)/B22 - 1;

% calculates the squared values of the metric above
[A12,B12] = deal(A1^2,B1^2);
[AA2,BB2,CC2,DD2,EE2] = deal(AA^2,BB^2,CC^2,DD^2,EE^2);     

% sets up the coefficients for the quartic equation
c = zeros(1,5);
c(1) = (A12^2)*AA2 + B12*(A12*(BB2-2*AA*CC) + B12*CC2);
c(2) = 2*B1*(B12*CC*EE + A12*(BB*DD - AA*EE));
c(3) = A12*((B12*(2*AA*CC-BB2) + DD2 - 2*AA*FF) - ...
           2*A12*AA2) + B12*(2*CC*FF+EE2);
c(4) = 2*B1*(A12*(AA*EE - BB*DD) + EE*FF);
c(5) = (A1*(A1*AA - DD) + FF)*(A1*(A1*AA + DD) + FF);

% calculates the roots of the polynomial
R = roots(c);
okR = imag(R) == 0;

% determines if there are any valid polynomial roots
if any(okR)
    % if so, calculate the scaled intersection coordinates
    yT0 = R(okR)*B1;
    xT0 = A1*sqrt(1 - (yT0.^2)/B12);
    
    % check to see the x-coordinate is correct
    for i = 1:length(yT0)
        if abs(ellipse2tr(xT0(i),yT0(i),AA,BB,CC,DD,EE,FF)) > 1e-6
            xT0(i) = -xT0(i);
        end
    end
    
    % rotate and translates the coordinates to the original frame ref
    [xT,yT] = rotateCoords(xT0,yT0,-p1);
    pT = [xT+h1,yT+k1];
    
else
    % case is there are no intersection points
    pT = [];
end

% --- ellipse to trace calculation
function Y = ellipse2tr(x,y,AA,BB,CC,DD,EE,FF)

Y = AA*x*x + BB*x*y + CC*y*y + DD*x + EE*y + FF;