% --- returns the base/comparison time unit conversion factor
function tMlt = getTimeMultiplier(tUnitB,tUnitC)

% sets the time multiplier based on the base/comparison time units
switch lower(tUnitB(1))
    case 'd' % base time units is days
        switch lower(tUnitC(1))
            case 'd' % comparison time units is days
                tMlt = 1;
                
            case 'h' % comparison time units is hours
                tMlt = 1/24;
                
            case 'm' % comparison time units is minutes
                tMlt = 1/(24*60);
                
            case 's' % comparison time units is seconds
                tMlt = 1/(24*60^2);
                
        end
        
    case 'h' % base time units is hours
        switch lower(tUnitC(1))
            case 'd' % comparison time units is days
                tMlt = 24;
                
            case 'h' % comparison time units is hours
                tMlt = 1;
                
            case 'm' % comparison time units is minutes
                tMlt = 1/60;
                
            case 's' % comparison time units is seconds
                tMlt = 1/(60^2);
                
        end      
        
    case 'm' % base time units is minutes
        switch lower(tUnitC(1))
            case 'd' % comparison time units is days
                tMlt = 24*60;
                
            case 'h' % comparison time units is hours
                tMlt = 60;
                
            case 'm' % comparison time units is minutes
                tMlt = 1;
                
            case 's' % comparison time units is seconds
                tMlt = 1/60;
                
        end
        
    case 's' % base time units is seconds
        switch lower(tUnitC(1))
            case 'd' % comparison time units is days
                tMlt = 24*60^2;
                
            case 'h' % comparison time units is hours
                tMlt = 60^2;
                
            case 'm' % comparison time units is minutes
                tMlt = 60;
                
            case 's' % comparison time units is seconds
                tMlt = 1;
                
        end        
end