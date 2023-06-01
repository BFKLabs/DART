% --- calculates the image interpolation rate (based on the image size)
function nI = getImageInterpRate()

nI = floor(max(getCurrentImageDim())/1000);