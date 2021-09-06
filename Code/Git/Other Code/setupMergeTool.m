% --- sets up the merge tool
function setupMergeTool(gTool)

% sets the default input arguments
if nargin == 1; gTool = 'meld'; end

% initialisations
gToolExe = findMergeTool(gTool);

% sets the mergtool type
[~,~] = system(sprintf('git config --global merge.tool %s',gTool));

% configures the mergetool path
[~,~] = system(sprintf(['git config --global ',...
                        'mergetool.%s.path "%s"'],gTool,gToolExe));
                    
% sets the mergetool prompt to false                     
[~,~] = system('git config --global mergetool.prompt false');

% sets the mergetool call
[~,~] = system(sprintf(['git config --global mergetool.%s.cmd "%s ',...
                        '\"$LOCAL\" \"$MERGED\" \"$REMOTE\" ',...
                        '--output \"$MERGED\""'],gTool,gTool));


% --- determines the path of the mergetool, gTool
function gToolExe = findMergeTool(gTool)

% initialisations (volume names)
vStr = {'A','B','C','D','E','F','G','H','I'};

% sets the program string based on the mergetool type
switch gTool
    case ('meld')
        baseDir = '\Program Files (x86)\Meld\Meld.exe';
end
        
% search all the volumes until a match is made
for i = 1:length(vStr)
    % sets the executable name with the new volume
    gToolExe = sprintf('%s:%s',vStr{i},baseDir);
    if exist(gToolExe,'file')
        % if the file exists, then exit the function 
        return
    end
end

% if there was no match, then return an empty string
gToolExe = '';