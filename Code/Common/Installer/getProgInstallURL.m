% --- retrieves the program installation URL
function [fURL,fExtn] = getProgInstallURL(pStr)

% initialisations
[fURL,fExtn] = deal([]);

% performs the install search based on operating system type
if ispc
    % case is pc

    % sets the pc program version URL
    switch pStr
        case 'git'
            % case is Git
            fExtn = '.exe';
            fURL = ['https://github.com/git-for-windows/git/releases',...
                    '/download/v2.37.0.windows.1/Git-2.37.0-64-bit.exe'];

        case 'ghcli'
            % case is Github-CLI
            fExtn = '.msi';
            fURL = ['https://github.com/cli/cli/releases/download',...
                    '/v2.13.0/gh_2.13.0_windows_amd64.msi'];

        case 'meld'
            % case is Meld
            fExtn = '.msi';
            fURL = ['https://download.gnome.org/binaries/win32',...
                    '/meld/3.20/Meld-3.20.4-mingw.msi'];

        case 'ffmpeg'
            % case is FFMPEG
            fExtn = '.zip';
            fURL = ['https://github.com/BtbN/FFmpeg-Builds/releases/',...
                    'download/latest/ffmpeg-n5.0-latest-win64-',...
                    'gpl-shared-5.0.zip'];

        case 'gs'
            % case is Ghostscript
            fExtn = '.exe';
            fURL = ['https://github.com/ArtifexSoftware/',...
                    'ghostpdl-downloads/releases/download/gs9561/'...
                    'gs9561w64.exe'];

        case 'xpdf'
            % case is XPDF
            fExtn = '.exe';
            fURL = 'https://dl.xpdfreader.com/XpdfReader-win64-4.04.exe';

        case 'java'
            % case is Java
            fExtn = '.exe';
            fURL = ['https://javadl.oracle.com/webapps/download/',...
                    'AutoDL?BundleId=',...
                    '246474_2dee051a5d0647d5be72a7c0abff270e'];

    end   



else
    % case is mac

    % sets the mac program version URL
    switch pStr
        case 'git'
            % case is Git
            fExtn = '.dmg';
            fURL = ['https://sourceforge.net/projects/',...
                    'git-osx-installer/files/latest/download'];

        case 'ghcli'
            % case is Github-CLI
            fExtn = '.tar.gz';
            fURL = ['https://github.com/cli/cli/releases/download',...
                    '/v2.13.0/gh_2.13.0_macOS_amd64.tar.gz'];

        case 'meld'
            % case is Meld
            fExtn = '.dmg';
            fURL = ['https://github.com/yousseb/meld/releases'...
                    '/download/osx-19/meldmerge.dmg'];

        case 'ffmpeg'
            % case is FFMPEG
            fExtn = '.7z';
            fURL = 'https://evermeet.cx/ffmpeg/ffmpeg-5.0.1.7z';

        case 'gs'
            % case is Ghostscript
            % => potential use through HomeBrew?

        case 'xpdf'
            % case is XPDF
            % => potential use through HomeBrew?

        case 'java'
            % case is Java
            fExtn = '.dmg';
            fURL = ['https://javadl.oracle.com/webapps/download/'...
                    'AutoDL?BundleId=',...
                    '246465_2dee051a5d0647d5be72a7c0abff270e'];

    end                

end