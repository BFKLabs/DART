% --- outputs each of the files 
function [outFile,ok] = runPackageInstaller(pkgFile,outDir)

% initialisations
ok = 1;
wStr = 'Decrypting Files';

% creates the decryption object
[~,hName] = system('HOSTNAME');
dObj = AES(hName(1:end-1),'SHA-1');

% creates the output directory (if it doesn't exist)
if ~exist(outDir,'dir'); mkdir(outDir); end

% reads the encrypted code from the file
fidIn = fopen(pkgFile,'r');
encStr = fread(fidIn,'*char')';

try 
    % attempts to decrypt the package code 
    dencStr = dObj.decrypt(encStr);    
    
catch
    % if the machine does not have permissions to install, then output an
    % error message to screen
    eStr = sprintf(['You do not permissions to install the package ',...
                    'on this machine']);
    waitfor(errordlg(eStr,'Invalid Permissions','modal'))
    
    % exits the function
    [outFile,ok] = deal([],false);
    return
end

% creates the waitbar figure
h = waitbar(0,wStr);
pause(0.05);

% splits the code into the separate function code blocks
fcnCode = strsplit(dencStr,'\n')';
indS = find(strContains(fcnCode,'///FUNCTION-START:'));
indF = [indS,[(indS(2:end)-1);length(fcnCode)]];

% writes all the code to file
nFile = length(indS);
outFile = cell(length(indS),1);
for i = 1:nFile
    % updates the progessbar
    wStrNw = sprintf('%s (%i of %i)',wStr,i,nFile);
    waitbar(i/(nFile+1),h,wStrNw);
    
    % creates the output file object
    codeBlk = fcnCode(indF(i,1):indF(i,2));
    outName = codeBlk{1}(strfind(codeBlk{1},':')+1:end);
    outFile{i} = fullfile(outDir,outName);    
    fidOut = fopen(outFile{i},'wb');
    
    % writes the function to file
    for j = 2:length(codeBlk)
        fwrite(fidOut,codeBlk{j});
    end
    
    % closes the file object
    fclose(fidOut);
end

% outputs the key file
fidKey = fopen(fullfile(outDir,'key.dat'),'wb');
fwrite(fidKey,dObj.encrypt(hName(1:end-1)));
fclose(fidKey);

% updates the waitbar figure
waitbar(1,h,'File Decryption Complete!');
pause(0.25);
close(h)