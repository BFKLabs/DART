% IPTGETPREF   Image Processing Toolbox で設定されている優先順位を表示
%
% PREFS = IPTGETPREF として、入力引数をつけない場合、カンレト値を含む
% Image Processing Toolboxのすべての優先順位の構造体を返します。
%
% VALUE = IPTGETPREF(PREFNAME) は、文字列 PREFNAME によって指定されて
% いる Image Processing Toolbox の優先順位の値を出力します。
% 有効な設定名の完全なリストについては、IPTSETPREF を参照してください。
% 優先名は、大文字小文字に関係なく、省略形を使うこともできます。
%
%
% 例題
% ----
%       value = iptgetpref('ImshowAxesVisible')
%
%   参考 IMSHOW, IPTSETPREF.


%   Copyright 1993-2005 The MathWorks, Inc.
