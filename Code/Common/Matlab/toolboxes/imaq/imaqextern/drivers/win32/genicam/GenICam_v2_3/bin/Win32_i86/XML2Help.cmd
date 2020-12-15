@echo off
setlocal

REM Deal with help
if "%1"=="/?" goto Usage
if "%1"=="/help" goto Usage
if "%1"=="" goto Usage

REM get rid of the file name's extension
REM example: %1=MyFile.xml => %FileBody%=MyFile
set FileBody=%~n1
set ThisDirectory=%~p0

ECHO Running XML2Help.cmd for '%FileBody%.xml'...

REM Create a subdirectory named %FileBody%
ECHO Creating output directory '%~p1%FileBody%'...
if exist %FileBody% goto :SubDirExists
md %FileBody%
:SubDirExists

REM Create a Doxygen configuration file
REM create the static pointer header files from the XML
ECHO Creating smart pointer headers '%FileBody%Param.h' and '%FileBody%Ptr.h'...
"%GENICAM_ROOT_V2_3%/bin/Win32_i86/GenApiPreProcessor_MD_VC80_v2_3.exe" -x %1 -s "%GENICAM_ROOT_V2_3%/xml/GenApi/GenApi_Params_h.xsl" -o %FileBody%/%FileBody%Params.h
"%GENICAM_ROOT_V2_3%/bin/Win32_i86/GenApiPreProcessor_MD_VC80_v2_3.exe" -x %1 -s "%GENICAM_ROOT_V2_3%/xml/GenApi/GenApi_Ptr_h.xsl" -o %FileBody%/%FileBody%Ptr.h

REM Note that Doxygen always uses the last instance of a command in a file
REM ignoring all previous ones
ECHO Creating Doxygen configuration file '%FileBody%.dox'...
type %ThisDirectory%XML2Help.dox > %FileBody%/%FileBody%.dox
echo %FileBody%Params.h >> %FileBody%/%FileBody%.dox
echo PROJECT_NAME="%FileBody%" >> %FileBody%/%FileBody%.dox
echo CHM_FILE = %FileBody%.chm >> %FileBody%/%FileBody%.dox

REM Run Doxygen and the M$ Help compiler
REM Note that both tools need to be run from the directory the files are in
ECHO Running Doxygen...
pushd
cd %FileBody%
doxygen %FileBody%.dox
cd html
ECHO Running help compiler...
hhc index.hhp
cd ..\..
popd

REM Copy the compiled HTML file and the index file to the %FileBody% directory
REM were also the created header files reside
ECHO Copying result files...
xcopy %FileBody%\html\%FileBody%.chm %FileBody%\*.* /y
xcopy %FileBody%\html\%FileBody%.chi %FileBody%\*.* /y

REM open the compiled header file
start "" %FileBody%\html\%FileBody%.chm

ECHO XML2Help...Done.

goto :end

:Usage
echo @on
ECHO This batch file creates a compiled HTML help (CHM) file from a GenICam XML file 
ECHO Preconditions:
ECHO    - Have Doxygen version 1.6.1 or higher installed 
ECHO    - Have the M$ HTML Help Workshop compiler installed
ECHO    - Run the tool with the GenICam v1.2 environment set up 
ECHO Usage:
ECHO     XML2Help XMLFile
ECHO Paramters:
ECHO   XMLFile = Name of the XML file to be used to ceate the headers and the CHM file
ECHO Output:
ECHO    The output is located in a sudirectory named like the XML file
ECHO Example:
ECHO   > XML2Help MyCamera.xml
ECHO   This will create a subdirectory  'MyCamera' containing the result.

:end
endlocal
