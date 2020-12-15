classdef FrameSize < uint32
    %Framesize defines an audio file IO packet sizes
    %   A packet is the size of a piece of audio data that will be written
    %   to or read from an audio file via an asyncio.Channel's
    %   InputStream or OutputStream. 
      
    % Author(s): NH
    % Copyright 2012 MathWorks, Inc.
 
  enumeration
        % The optimal frame size was determined doing performance profiling 
        % on all the formats supported in the audio plugins managed by 
        % audio.file.PluginManager.  A 64k chunk size gave the best
        % performance across all formats.
        Optimal (65536)
  end
end