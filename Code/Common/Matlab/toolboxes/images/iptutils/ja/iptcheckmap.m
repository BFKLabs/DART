% IPTCHECKMAP   カラーマップの有効性をチェック
%
% IPTCHECKMAP(MAP,FUNC_NAME,VAR_NAME,ARG_POS) は、MAP が有効なMATLABの
% カラーマップかどうかをチェックし、正しくない場合は書式化されたエラー
% メッセージを出力します。
%
% FUNC_NAME は、カラーマップをチェックする関数を識別するために書式化された
% エラーメッセージで使われる名前を指定する文字列です。
%
% VAR_NAME は、チェックされる引数を識別するために書式化されたエラーメッセージ
% で使われる名前を指定する文字列です。
%
% ARG_POS は、関数の引数リストでチェックされる引数の位置を示す正の整数
% です。IPTCHECKMAP はこの数を序数に変換し、書式化されたエラーメッセージ
% にこの情報を含めます。
%
% 例
% --
%    
%       bad_map = ones(10);
%       iptcheckmap(bad_map,'func_name','var_name',2)
%
%   参考 IPTCHECKHANDLE, IPTCHECKINPUT, IPTCHECKNARGIN, IPTCHECKSTRS,
%        IPTNUM2ORDINAL.


%   Copyright 1993-2006 The MathWorks, Inc.
