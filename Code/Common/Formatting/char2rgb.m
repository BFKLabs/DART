function rgbvec = char2rgb (charcolor)
%function rgbvec = char2rgb (charcolor)
%
%converts a character color (one of 'r','g','b','c','m','y','k','w') to a 3
%value RGB vector
%if charcolor is a string (vector of chars), the result is a Nx3 matrix of
%color values, where N is the length of charcolor

charwarning = false;

switch(lower(charcolor))
    case 'r'
        rgbvec = [1 0 0];
    case 'g'
        rgbvec = [0 1 0];
    case 'b'
        rgbvec = [0 0 1];
    case 'c'
        rgbvec = [0 1 1];
    case 'm'
        rgbvec = [1 0 1];
    case 'y'
        rgbvec = [1 1 0];
    case 'w'
        rgbvec = [1 1 1];
    case 'k'
        rgbvec = [0 0 0];
    otherwise
        charwarning = true;            
end

if (charwarning)
    warning('RGB2VEC:BADC', 'Only r,g,b,c,m,y,k,and w are recognized colors');
end
