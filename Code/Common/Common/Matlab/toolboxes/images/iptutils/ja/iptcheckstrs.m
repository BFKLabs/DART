% IPTCHECKSTRS   テキスト文字列の有効性をチェック
%
% OUT = IPTCHECKSTRS(IN,VALID_STRINGS,FUNC_NAME,VAR_NAME,ARG_POS) は、
% テキスト文字列 IN の有効性をチェックします。 テキスト文字列がセル配列
% VALID_STRINGS 内のテキスト文字列の1つと一致する場合、IPTCHECKSTRS は
% OUT 内に有効なテキスト文字列を出力します。 テキスト文字列が一致しない
% 場合は、IPTCHECKSTRS は書式化されたエラーメッセージを出力します。
%
% IPTCHECKSTRS は、IN と VALID_STRINGS 内の文字列の間で大文字小文字を
% 区別しない不明瞭ではない一致を探します。
%
% VALID_STRINGS は、テキスト文字列を含むセル配列です。
%
% FUNC_NAME は、テキスト文字列をチェックする関数を識別するために書式化
% されたエラーメッセージで使われる名前を指定する文字列です。
%
% VAR_NAME は、チェックされる引数を識別するために書式化されたエラーメッセージ
% で使われる名前を指定する文字列です。
%
% ARG_POS は、関数の引数リストでチェックされる引数の位置を示す正の整数
% です。 IPTCHECKSTRS はこの数を序数に変換し、書式化されたエラーメッセージ
% にこの情報を含めます。
%
% 例題
% -----
%       % エラーメッセージを出力するために、いくつかのテキスト文字列の
%       % セル配列を定義し、セル配列内にない他の文字列を渡します。
%       iptcheckstrs('option3',{'option1','option2'},'func_name','var_name',2)
%
%   参考 IPTCHECKHANDLE, IPTCHECKINPUT, IPTCHECKMAP, IPTCHECKNARGIN
%            IPTNUM2ORDINAL.


%   Copyright 1993-2005 The MathWorks, Inc.
