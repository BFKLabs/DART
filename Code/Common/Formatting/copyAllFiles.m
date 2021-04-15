% --- copies all the files in copyDir to the destination, destDir
function copyAllFiles(copyDir,destDir,varargin)
 
% global variables
global isFull isAnalyDir
if isempty(isAnalyDir); isAnalyDir = false; end
 
% retrieves the file details from that within the copy directory
copyData = dir(copyDir);
[~,finalDir] = fileparts(copyDir);
 
% removes all the *.m/*.fig files in the destination directory (removes any
% previous file versions to remove any overlaps). do not do this for the
% analysis function directory
A = [dir(fullfile(destDir,'*.m'));dir(fullfile(destDir,'*.fig'))];
if ~isempty(A) && ~isAnalyDir
    cellfun(@(x)(delete(fullfile(destDir,x))),field2cell(A,'name'));
end
 
% loops through all the files in the directory copying them from the
% copying directory to the destination directory
for i = 1:length(copyData)
    % only copy over valid files
    if ~(strcmp(copyData(i).name,'.') || strcmp(copyData(i).name,'..'))
        if copyData(i).isdir && (nargin == 2)
            % creates a new sub-directory for copying/destination
            copyDirNw = fullfile(copyDir,copyData(i).name);
            destDirNw = fullfile(destDir,copyData(i).name);
                        
            % copies over the sub-directories
            copyAllFiles(copyDirNw,destDirNw);
        else
            % determines if the directory is the utilities directory
            isUtil = strContainsT(copyDir,'Utilities');
            
            % determines whether or not to copy            
            if isFull
                % determines if the directory is a toolbox directory
                hasTool = strContainsT(copyDir,'toolboxes');             
                
                if ~hasTool                                       
                    if isUtil                        
                        isCopy = true;
                    else
                        switch finalDir
                            case 'mmread' 
                                % case is the mmread directory
                                isCopy = true;
                            case {'xlwrite','poi_library'} 
                                % xlwrite java object directory
                                isCopy = true;                            
                            case {'Test Files', 'External Files'} 
                                % case is the external/test files
                                isCopy = true;       
                            case ('Matlab')
                                isCopy = true; 
                            case ('Resources')
                                isCopy = true;
                            case ('Para Files')
                                fName = {'ButtonCData.mat','ProgPara.mat'};
                                isCopy = any(cellfun(@(x)...
                                       (strcmp(x,copyData(i).name)),fName));
                            otherwise
                                % only copy .m or .fig files
                                [~,~,fExtn] = fileparts(copyData(i).name);            
                                isCopy = strcmp(fExtn,'.m') ...
                                        || strcmp(fExtn,'.fig');            
                        end
                    end
                else                                   
                    isCopy = true;
                end
            else
                if isUtil 
                    isCopy = strcmp(finalDir,'Serial Builds');

                elseif strcmp(finalDir,'Matlab') || ...
                       strcmp(finalDir,'Resources')
                    isCopy = true;
                    
                else
                    % only copy .m or .fig files
                    [~,~,fExtn] = fileparts(copyData(i).name);            
                    isCopy = strcmp(fExtn,'.m') || strcmp(fExtn,'.fig');             
                end
            end
                
            % ensures that only non-empty files are copied
            isCopy = isCopy && (copyData(i).bytes > 0);
            
            % if a valid file to copy, then copy the file
            if isCopy
                % if the destination does not exist, then create it
                if ~exist(destDir,'dir')
                    mkdir(destDir)
                end
 
                % copies over the file
                try
                    nwFile = fullfile(copyDir,copyData(i).name);
                    copyfile(nwFile,destDir,'f');
                catch
                    try
                        cpStr = sprintf('cp -p "%s" "%s"',nwFile,destDir);
                        [~,~] = system(cpStr);
                    catch ME
                        rethrow(ME)
                    end
                end
            end
        end
    end
end

% --- wrapper function for determining if a string has a pattern. this is
%     necessary because there are 2 different ways of determining this
%     depending on the version of Matlab being used
function hasPat = strContainsT(str,pat)

if iscell(str)
    hasPat = cellfun(@(x)(strContainsT(x,pat)),str);
end

try
    % attempts to use the newer version of the function
    hasPat = contains(str,pat);
catch
    % if that fails, use the older version of the function
    hasPat = ~isempty(strfind(str,pat));
end
