% --- converts time in seconds to a vector (of format DD/hh/mm/ss) --- %
function V = sec2vec(T)

% memory allocation
T = reshape(T,length(T),1);
V = zeros(length(T),4);

% sets the duration of the day, hour and mins in seconds
dTime = [24*60^2,60^2,60,1];

% calculates the time over the vector columns
for i = 1:(length(dTime)-1)
    V(:,i) = floor(T/dTime(i));
    T = T - V(:,i)*dTime(i);
end
    
% sets the seconds field
V(:,end) = T;
    