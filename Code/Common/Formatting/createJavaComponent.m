function [jSP,hC] = createJavaComponent(jSP0,tPos,hParent)

wState = warning('off','all');
[jSP,hC] = javacomponent(jSP0, tPos, hParent);
warning(wState);