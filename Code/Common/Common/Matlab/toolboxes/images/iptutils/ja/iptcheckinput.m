%IPTCHECKINPUT  配列の有効性をチェック
%
%   IPTCHECKINPUT(A,CLASSES,ATTRIBUTES,FUNC_NAME,VAR_NAME, ARG_POS) は、配列 A 
%   の有効性をチェックし、正しくない場合、書式化されたエラーメッセージを返します。
%   A はすべてのクラスの配列になります。
%
%   CLASSES は、A が属するために必要なクラスの設定を含む文字列のセル配列です。
%   たとえば、{'logical','cell'} として CLASSES を指定する場合、A は logical の
%   配列かセル配列のいずれかである必要があります。文字列 'numeric' は、クラス 
%   uint8, uint16, uint32, int8, int16, int32, single, double に対する省略として
%   解釈されます。
%
%   ATTRIBUTES は、A を満足しなければならない属性の設定を指定する文字列のセル
%   配列です。たとえば、{'real','nonempty','finite'} として ATTRIBUTES を指定
%   する場合、A は実数の非スパースでなければならず、有限値のみを含まなければ
%   なりません。属性のサポートされるリストはつぎのようになります:
%
%       2d               nonempty            nonzero       row
%       column           nonnan              odd           scalar
%       even             nonnegative         positive      twod
%       finite           nonsparse           real          vector
%       integer
%
%   FUNC_NAME は、入力をチェックする関数を識別するために書式化されたエラー
%   メッセージで使われる名前を指定する文字列です。
%
%   VAR_NAME は、チェックされる引数を識別するために書式化されたエラーメッセージ
%   で使われる名前を指定する文字列です。
%
%   ARG_POS は、関数の引数リストでチェックされる引数の位置を示す正の整数です。
%   IPTCHECKINPUT はこの数を序数に変換し、書式化されたエラーメッセージにこの
%   情報を含めます。
%
%   例
%   -------
%   % このエラーメッセージを出すために、3 次元配列を作成し、属性 '2d' に
%   % 対してチェックします。
%       A = [ 1 2 3; 4 5 6 ];
%       B = [ 7 8 9; 10 11 12];
%       C = cat(3,A,B);
%       iptcheckinput(C,{'numeric'},{'2d'},'my_func','my_var',2)
%
%   参考 IPTCHECKHANDLE, IPTCHECKMAP, IPTCHECKNARGIN, IPTCHECKSTRS,
%        IPTNUM2ORDINAL.


%   Copyright 1993-2007 The MathWorks, Inc.
