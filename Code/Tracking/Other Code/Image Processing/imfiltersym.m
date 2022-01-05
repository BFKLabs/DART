function ILF = imfiltersym(I,hS)

if isempty(hS)
    ILF = I;
else
    ILF = imfilter(I,hS,'symmetric');
end