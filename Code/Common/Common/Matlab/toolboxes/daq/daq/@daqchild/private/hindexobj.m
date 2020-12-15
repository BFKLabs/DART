function varargout=hindexobj(obj,varargin)
%hindexobj paren index into an object calling subsref

[varargout{1:nargout}]=subsref(obj,substruct('()',varargin));
