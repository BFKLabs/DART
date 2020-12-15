%IPTSETPREF  Image Processing Toolbox の設定値
%
%   IPTSETPREF(PREFNAME) は、PREFNAME で指定した Image Processing Toolbox の
%   設定に対する有効な値を表示します。
%
%   IPTSETPREF(PREFNAME,VALUE) は、文字列 PREFNAME を VALUE に設定することに
%   より、Image Processing Toolbox を設定します。
%
%   設定の名前は大文字小文字を区別せず、省略形を使用することができます。
%   デフォルト値は、中括弧 ({}) で囲まれます。
%
%   以下の設定値をセットすることができます。
%
%   'ImshowBorder'        {'loose'} または 'tight'
%
%        IMSHOW が、Figure ウィンドウ内でイメージの回りに境界を含ませるか
%        否かを制御します。利用可能な値は以下のとおりです。
%
%        'loose' -- Figureウィンドウのエッジとイメージの間に境界を含ませます。
%                   そして、軸ラベル、タイトル等を除去します。
%
%        'tight' -- Figure のサイズを Figure 全体にイメージが入るように
%                   調整します。
%
%        注意: イメージが非常に小さい、または Figure 内のイメージと軸以外に
%        他のオブジェクトが存在する場合、Figure の境界が残ることがあります。
%
%   'ImshowAxesVisible'   'on' または {'off'}
%
%        IMSHOW が軸ボックスと目盛りラベルを付けてイメージを表示するか否かを
%        制御します。利用可能な値は以下のとおりです。
%
%        'on'  -- 座標軸のボックスと目盛りラベルを含む。
%
%        'off' -- 座標軸のボックスと目盛りラベルを含まない。
%
%   'ImshowInitialMagnification'   {100}、任意の数値、または 'fit'
%
%        IMSHOW で表示されたイメージの初期倍率を制御します。利用可能な値は
%        以下のとおりです。
%
%        任意の数値 -- IMSHOW は、パーセンテージで数値を解釈します。
%        デフォルト値は 100 です。100 % の倍率は、すべてのイメージピクセルに
%        対して 1 つのスクリーンピクセルがあることを意味します。
%
%        'fit'             -- ウィンドウ全体に適合するようにイメージを
%                             スケーリングします。
%
%        IMSHOW を呼び出すときに 'InitialMagnification' パラメータを指定する
%        ことで、またはイメージを表示した後に手動で TRUESIZE 関数を呼び出すことで、
%        この設定をオーバーライドすることができます。
%
%   'ImtoolInitialMagnification'   {'adaptive'}, 任意の数値、または 'fit
%
%        IMTOOL で表示されたイメージの初期倍率を制御します。利用可能な値は
%        以下のとおりです。
%
%        'adaptive'        -- 全体のイメージを表示します。イメージをスクリーン上で
%                             100% で表示するには大きすぎる場合、スクリーン上に
%                             適合する最も大きい倍率でイメージを表示します。
%
%        任意の数値        -- IMTOOL は、パーセンテージで数値を解釈します。
%                             100 % の倍率は、すべてのイメージピクセルに対して 
%                             1 つのスクリーンピクセルがあることを意味します。
%
%        'fit'             -- ウィンドウ全体に適合するようにイメージを
%                             スケーリングします。
%
%        IMTOOL を呼び出すときに、'InitialMagnification' パラメータを指定する
%        ことで、この設定をオーバーライドすることができます。
%
%   'ImtoolStartWithOverview'    true または {false}
%
%       Image Tool (IMTOOL) 内のイメージを表示するときにデフォルトで
%       オーバービューツールを開くかどうかを制御します。
%
%       true               -- Image Tool を開始するときにオーバービューツールを開く。
%
%       false              -- Image Tool を開始するときにオーバービューツールを開かない。
%
%   'UseIPPL'              {true} または false
%
%       いくつかのツールボックス関数が Intel Performance Primitives Library 
%       (IPPL) を使用するかどうかを制御します。利用可能な値は以下のとおりです。
%
%       true               -- IPPL の使用を有効にする。
%
%       false              -- IPPL の使用を無効にする。
%
%       注意: この設定値をセットすると、読み込まれた MEX-ファイルのすべてを
%       クリアする効果があります。
%
%   例
%   --
%       iptsetpref('ImshowBorder', 'tight')
%
%   参考 IMSHOW, IPTGETPREF, TRUESIZE.


%   Copyright 1993-2009 The MathWorks, Inc.
