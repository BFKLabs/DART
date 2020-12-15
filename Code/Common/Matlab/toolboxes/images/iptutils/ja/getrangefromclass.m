% GETRANGEFROMCLASS  イメージのクラスに基づくダイナミックレンジを取得
% 
%   RANGE = GETRANGEFROMCLASS(I) は、イメージ I のクラスタイプに基づき
%   ダイナミックレンジを出力します。
%
%   クラスサポート
%   -------------
%   I は、数値、または、論理値です。RANGE は、double の 2 要素のベクトルです。
%
%   注意
%   ----
%   single と double のデータに対して、GETRANGEFROMCLASS は、double と 
%   single のイメージがMATLABで解釈される方法と一致しているため範囲 [0 1] 
%   を出力します。 整数のデータについては、GETRANGEFROMCLASS はクラスの
%   範囲を出力します。 たとえば、クラスが uint8 の場合、ダイナミックレンジは
%   [0 255] になります。
%
%   例
%   --
%       % int16 のイメージのダイナミックレンジを取得
%       CT = dicomread('CT-MONO2-16-ankle.dcm');
%       r = getrangefromclass(CT)
%
%   参考 INTMIN, INTMAX.

  
%   Copyright 1993-2007 The MathWorks, Inc.
