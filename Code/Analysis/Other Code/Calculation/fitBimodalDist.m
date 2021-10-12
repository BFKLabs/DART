% --- fits a bi-modal distribution to the data
function [p,Yfit] = fitBimodalDist(X,Y)

% precalculations
ii = Y > 0;

% offsets the angles by 90 degrees (so x > 0)
[x,y] = deal(reshape(X+90,length(X),1),reshape(Y/sum(Y),length(Y),1));
x([1 end]) = x([1 end]) + 0.001*[1;-1];

% sets the fit-type equation parameters (log-normal distribution)
g = fittype(['A*((exp(-((log(180-x)-mu)^2)/(2*sigma^2)))/((180-x)*sigma*sqrt(2*pi))',...
             '+exp(-((log(x)-mu)^2)/(2*sigma^2))/(x*sigma*sqrt(2*pi)))'],...
            'coeff',{'mu','sigma','A'});
                
% sets the initial value and the lower/upper bounds        
x0 = [4  1.5  1.0];
xL = [1  0.1  0.1];
xU = [10 5.0 50.0];   

% % gamma distribution
% g = fittype(['A*((((x/b)^(g-1))*exp(-(x/b))) + ((((180-x)/b)^(g-1))*',...
%              'exp(-((180-x)/b))))/(b*gamma(g))'],'coeff',{'b','g','A'});             
% 
% % sets the initial value and the lower/upper bounds        
% x0 = [3  15  1.0];
% xL = [1   5  0.1];
% xU = [10 50 10.0];        

% % sets the fit-type equation parameters (power log-normal distribution)
% g = fittype(['A*((p./(s*x)).*normpdf(log(x)/s).*normcdf(-log(x)/s).^(p-1) + ',...
%              '(p./(s*(1-x))).*normpdf(log(1-x)/s).*normcdf(-log(1-x)/s).^(p-1))'],...
%              'coeff',{'p','s','A'});
% 
% % sets the initial value and the lower/upper bounds        
% x = x/180;
% x0 = [  5.00  1.5 0.10];
% xL = [  0.01  0.1 0.01];
% xU = [100.00 10.0 1.00]; 
%          
% g = fittype(['A*(((sqrt(x/b)+sqrt(b/x))/(2*g*x))*normpdf((sqrt(x/b)-sqrt(b/x))/g) + ',...
%              '((sqrt((180-x)/b)+sqrt(b/(180-x)))/(2*g*(180-x)))*normpdf((sqrt((180-x)/b)-sqrt(b/(180-x)))/g))'],...
%              'coeff',{'b','g','A'});
% x0 = [ 40.0  0.40  1.00];
% xL = [  1.0  0.10  0.01];
% xU = [100.0  1.00 10.00]; 

% sets the fit options struct
fOpt = fitoptions('method','NonlinearLeastSquares','Lower',xL,...
                  'Upper',xU,'StartPoint',x0,'MaxFunEvals',1e10,...
                  'MaxIter',1e10);
                                
% runs the solver
% if sum(ii) < 3
%     [pExp,G] = fit(x,y,g,fOpt); 
% else
    
% end

% calculates the fitted values
if sum(ii) < 3
    % case is there is not enough data points for data fitting
    Yfit = zeros(size(x));
    p = struct('R2',0,'mu',NaN,'sigma',NaN,'A',NaN);
else
    % calculates the fitted values
    [pExp,G] = fit(x(ii),y(ii),g,fOpt); 
    Yfit = calcFittedValues(g,pExp,x);

    % retrieves the coefficient values and confidence intervals
    try
        pW = 2*1.96;
        [pp,ppS] = deal(coeffvalues(pExp),diff(confint(pExp),[],1)/pW);
    catch
        [pp,ppS] = deal(NaN(1,3));
    end

    % sets the fitted values into the output data struct
    [p,fStr] = deal(struct('R2',G.rsquare),fieldnames(pExp));
    for i = 1:length(fStr)   
        p = setStructField(p,fStr{i},zeros(1,2));
        eval(sprintf('p.%s(1) = pp(i);',fStr{i}));
        eval(sprintf('p.%s(2) = ppS(i);',fStr{i}));
    end
end