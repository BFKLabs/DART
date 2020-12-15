function [linkTag,endLinkTag] = linkToAlgDefaultChangeCsh(CshTag)
%

%linkToAlgDefaultChangeCsh utility that creates HTML tags for linking to 
% context sensitive help (CSH). These links appear in warning and error messages 
% thrown during transition as we change the default algorithms.
%
% Input CshTag is the tag that identifies the CSH you want the link in the 
% error/warning to point to.
% 
% Outputs linkTag and endLinkTag are HTML tags that have to surround the
% text in the error/warning that you want to be a hyperlink.

%   Copyright 2012 The MathWorks, Inc.

% Don't add links to error/warning if running no-desktop, or deployed code, etc.
enableLinks = feature('hotlinks') && ~isdeployed;

% Create links
if enableLinks
    linkCmd = '<a href = "matlab: helpview([docroot ''/toolbox/optim/msg_csh/optim_msg_csh.map''],''%s'',''CSHelpWindow'');">';
    linkTag = sprintf(linkCmd,CshTag);
    endLinkTag = '</a>';
else
    linkTag = '';
    endLinkTag = '';
end
