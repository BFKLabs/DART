% function that outputs whether the matlab version uses HG1 graphics
function output = isHG1()

output = verLessThan('matlab','8.4');