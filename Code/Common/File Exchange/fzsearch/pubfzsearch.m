%% Fuzzy Search
% |Fuzzy Search aka Approximate String Matching, Text Searching with
%  Errors.|
%% Syntax
% |_d_ = fzsearch(_r,p_)|
%
% |_d_ = fzsearch(_r,p,n_)| 
%
% |_d_ = fzsearch (_r,p,n_,case)|
%
% |[ _d,A_]  =  fzsearch(_r,p_)|
%% Description
% Function |*fzsearch(_r,p,n,case_)*|  finds the best or predetermined 
% approximate matching between substrings of a string |_r_| (reference) 
% and a string |_p_| (pattern). The Levenshtein distance is used as a measure 
% of matching. Levenshtein distance is the minimum number of single-character 
% substitutions, deletions and insertions required to convert string |_A_|
% to string |_B_|.
%
% |_d_ = fzsearch(_r_)| computes |NaN|.
%
% |_d_ = fzsearch(_r,p_)| computes the best matching between substrings of 
% the reference and a pattern.
% |_d_|  is a vector, where |_d_(1)| is a distance and |_d_(2), _d_(3)...| 
% are indexes of the ends of the best matching substrings.
%
% |[ _d,A_]  =  fzsearch(_r,p_)| computes as above and a cell array A  
% of the best matching substrings.
%
% |_d_ = fzsearch(_r,p,n_)| computes the match between substrings of _r_ and 
% _p_ in interval from the best match (say, |_m_|) to |_m_ + _n_|. 
% |_d_| is a |(_n_ + 1)| cell array. Each cell contains a vector which first 
% number is a distance |_m + k, k = 0 .. n_| and others are indexes 
% of the ends of substrings with the same distance from |_p_|.
%
% |_d_ = fzsearch (_r,p,n_,case)| is the same of the previous but the case 
% is ignored for |case > 0|.
%
% |_d_ = fzsearch('','')| computes |_d_ = 0|.
%
% |_d_ = fzsearch('', _p_)| computes |_d_(1) = numel(_p_)| and |_d_(2) = 0|.
%
% |_d_ = fzsearch(_r_,'')| computes |_d_(1) = 1| and |_d_(_i_) = _i_-1, 
% _i_ = 2...numel(_r_)+1|.
%% References
% # https://en.wikipedia.org/wiki/Approximate_string_matching   
% # http://algolist.manual.ru/search/lcs/   
% # http://algolist.manual.ru/search/fsearch/k_razl.php

%% Examples
%  
% * |*1. Distance of the best matching, indexes of the ends of the best 
% matcing substrings and a set of the best matching substrings*|
reference = '2171351273745126271432'
pattern = '2345'
[d,A]=fzsearch(reference,pattern);
fprintf('A distance of the best matching: %2.0f\n',d(1))
disp('Indexes of the ends of substrings:')
disp(d(2:end))
disp('A set of substrings:')
disp(A)
%%
% * |*2. Indexes of the ends of the best matching substrings and indexes of 
% the ends of substrings which distance from the pattern more than the best
% one by 1 and 2*|
reference = 'ddbababceabadecdddcedeabc'
pattern = 'abcde'
n = 2;
[d,A] = fzsearch(reference,pattern,n);
d1= d{1};
for i = 1:d1(1)+n
d1 = d{i};
fprintf('A distance of the matching: %2.0f\n',d1(1))
disp('Indexes of the ends of substrings:')
disp(d1(2:end))
end
%%
% |*3. Comparison of the fuzzy search for insensitive and sensitive cases*|
reference = 'AdaCDabcAAbbDabdEdbD'
pattern = 'abcDe'
disp('Case insensitive:')
d = fzsearch(reference,pattern,0,1);
disp(d{1})
disp('Case sensitive:')
disp(fzsearch(reference,pattern))
