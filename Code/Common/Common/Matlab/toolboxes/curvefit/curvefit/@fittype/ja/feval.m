%FEVAL  FITTYPE オブジェクトの実行
%
%   F = FEVAL(FITOBJ,A,B,...,X) は、係数 A,B,... とデータ X を持つ FITOBJ の
%   関数値 F を実行します。
%
%   [F, J] = FEVAL(FITOBJ,A,B,...,X) は、係数 A,B,... とデータ X を持つ 
%   FITOBJ の関数値 F と係数に関するヤコビアン J を実行します。
%
%   FEVAL(FITOBJ,A,B,...,X,Y) は、データ X,Y で係数 A,B,... を持つ FITOBJ を
%   実行します。ここで、FITOBJ は曲面 (すなわち、2 変数の関数) を表します。


%   Copyright 1999-2009 The MathWorks, Inc.

