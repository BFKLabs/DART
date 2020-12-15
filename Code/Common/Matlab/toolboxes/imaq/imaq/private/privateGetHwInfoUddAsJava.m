function hwinfo = privateGetHwInfoUddAsJava
% PRIVATEGETHWINFOUDDASJAVA Returns a HWINFO object to Java.
%
%   HWINFO = PRIVATEGETHWINFOUDDASJAVA returns a Image Acquisition Toolbox
%   hardware information object to Java.
%
%   This is a helper file meant to be called from Java code.

%    DT 11/2004
%    Copyright 2004 The MathWorks, Inc.

imaqmex('imaqregisterhwinfo');
hw = imaq.hwinfo;
hwinfo = java(hw);