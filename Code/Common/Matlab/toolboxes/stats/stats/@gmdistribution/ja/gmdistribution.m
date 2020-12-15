%GMDISTRIBUTION  ガウス混合分布クラス
%
%   GMDISTRIBUTION クラスのオブジェクトは、複数の多変量ガウス分布要素の
%   混合で構成される多変量分布であるガウス混合分布を定義します。与えられた 
%   GMDISTRIBUTION オブジェクトに対する要素数は固定です。それぞれの多変量
%   ガウス要素は、平均と共分散で定義され、混合要素は、混合比のベクトルで
%   定義されます。
%
%   分布パラメータを指定してガウス混合分布を作成するには、GMDISTRIBUTION 
%   コンストラクタを使用してください。ガウス混合分布モデルをデータに近似するには、
%   GMDISTRIBUTION.FIT を使用してください。
%
%   K 個の要素を持つガウス混合分布は、D 次元において、以下のプロパティを
%   持っています。
%
%      NDimensions  混合分布 D 内の多変量ガウス要素ごとの次元数。
%      DistName     分布名 'gaussian mixture distribution'。
%      NComponents  混合要素数 K。
%      PComponents  各要素の混合比を含む 1×K のベクトル。
%      CovType      要素の共分散行列が対角行列になるよう制限される場合は 
%                   'diagonal'。そうでない場合は 'full'。
%      SharedCov    要素の共分散行列が同じ (プールされた共分散) になるよう
%                   制限される場合は true。そうでない場合は false。
%      mu           要素の平均の K×D の行列。
%      Sigma        要素の共分散行列を含む配列、または、行列。
%                   Sigma は以下のいずれかになります。
%                    * 共分散のフォームで制限がない場合は D×D×K 配列。
%                      この場合、Sigma(:,:,J) は要素 J の共分散行列です。
%                    * 共分散行列は対角行列になるよう制限されるが、全体を同じ
%                      要素にするよう制限されない場合は 1×D×K 配列。
%                      この場合、Sigma(:,:,J) は要素 J の共分散行列の
%                      対角要素を含みます。
%                    * 共分散行列は全体を同じ要素にするよう制限されるが、
%                      対角行列になるよう制限されない場合は D×D 行列。
%                      この場合、Sigma は共通の共分散行列です。
%                    * 共分散行列は対角行列になるよう、かつ、全体を同じ
%                      要素にするよう制限される場合は 1×D ベクトル。
%                      この場合、Sigma は共通の共分散行列の対角要素を含みます。
%
%   GMDISTRIBUTION.FIT を使ってデータに近似することで、作成されたガウス混合分布
%   オブジェクトは、さらに以下のプロパティを持っています。
%
%      NlogL        近似の負の対数尤度。
%      AIC          2*NlogL + 2*(推定パラメータ数) として定義される近似に
%                   対する赤池の情報規範。
%      BIC          2*NlogL + (推定パラメータ数 * log(N)) として定義される
%                   近似に対するベイズの情報規範。
%      Converged    近似アルゴリズムが収束した場合は true。アルゴリズムが
%                   収束しない場合は false。
%      Iters        近似アルゴリズムで与えられる繰り返し回数。
%      RegV         FIT メソッドへの 'Regularize' 入力パラメータに対して
%                   与えられる値。
%
%   参考 GMDISTRIBUTION/GMDISTRIBUTION, GMDISTRIBUTION/FIT,
%        GMDISTRIBUTION/CLUSTER, GMDISTRIBUTION/PDF, GMDISTRIBUTION/CDF,
%        GMDISTRIBUTION/RANDOM, GMDISTRIBUTION/POSTERIOR,
%        GMDISTRIBUTION/MAHAL.


%   Copyright 2007-2008 The MathWorks, Inc.
