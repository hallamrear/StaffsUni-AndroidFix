@ECHO OFF
SETLOCAL enableextensions enabledelayedexpansion
	
SET JDK_FILE_NAME=JDK_17.0.9
SET JDK_DOWNLOAD_LINK=https://download.oracle.com/java/17/archive/jdk-17.0.9_windows-x64_bin.zip
SET JDK_LOCATION_REGISTRY_KEY=Jdk17Path_h3457115883
SET JDK_ENABLED_REGISTRY_KEY=JdkUseEmbedded_h2297287597

SET NDK_FILE_NAME=NDK_r27c
SET NDK_DOWNLOAD_LINK=https://dl.google.com/android/repository/android-ndk-r27c-windows.zip
SET NDK_LOCATION_REGISTRY_KEY=AndroidNdkRootR27C_h1677875693
SET NDK_ENABLED_REGISTRY_KEY=NdkUseEmbedded_h2501497897

SET ASDK_LOCATION="C:\Programs\AndroidStudio\SDK"
SET ASDK_LOCATION_REGISTRY_KEY=AndroidSdkRoot_h2651068356
SET ASDK_ENABLED_REGISTRY_KEY=SdkUseEmbedded_h968012308

SET REGISTRY_ENTRY_LOCATION="HKEY_CURRENT_USER\Software\Unity Technologies\Unity Editor 5.x"

GOTO PROGRAM_START

:FUNC_CONVERT_TO_HEX	
	SET inputvar=%~1
	ECHO Patch (String): %inputvar%
			
	FOR /f "usebackq delims=" %%a IN (`
	  powershell -c "$bytes = [System.Text.Encoding]::UTF8.GetBytes('%inputvar%'); $binaryString = ($bytes | ForEach-Object { [System.BitConverter]::ToString($_) }) -join ''; $binaryString"
	`) DO SET "HexNum=%%a"
				
	SET "hexOutput=%HexNum%"
	ECHO Patch (Hex): %hexOutput%
EXIT /B 0

:PROGRAM_START

IF EXIST temp\ (GOTO DOWNLOADING_FILES) ELSE (GOTO CREATE_TEMP_FOLDER)

:CREATE_TEMP_FOLDER
ECHO Making temporary directory for downloads.
mkdir temp\

:DOWNLOADING_FILES
CALL :FUNC_DOWNLOAD_AND_UNZIP %NDK_FILE_NAME% %NDK_DOWNLOAD_LINK%
CALL :FUNC_DOWNLOAD_AND_UNZIP %JDK_FILE_NAME% %JDK_DOWNLOAD_LINK%
GOTO VERIFY_REG_EDIT

:FUNC_DOWNLOAD_AND_UNZIP
	::If parameters are invalid, exit with error.
	IF (%~1=="") EXIT /B 1
	IF (%~2=="") EXIT /B 1

	::Storing parameters as variables.
	SET fileName=%~1
	SET fileLink=%~2
	
	::If unzipped folder exists, we don't need to do anything.
	IF EXIST %fileName%\ (GOTO UNZIPPED_FOLDER_ALREADY_EXISTS)

	::If the zip exists, move to unzipping.
	IF EXIST temp\%fileName%.zip (GOTO UNZIP_FILE)

	::Downloading zip
	ECHO Downloading %fileName% Zip...
	curl -L %fileLink% > temp\%fileName%.zip
	ECHO Done!
	GOTO :UNZIP_FILE
	:PRINT_ZIP_ALREADY_EXISTS
	ECHO %fileName% Zip already exists within temp folder.
	GOTO :UNZIP_FILE

	:UNZIP_FILE
	::If unzipped folder exists, no need to re-unzip.
	IF EXIST %fileName%\ (GOTO UNZIPPED_FOLDER_ALREADY_EXISTS)
	ECHO Unzipping %fileName% Zip...
	POWERSHELL Expand-Archive temp\%fileName%.zip -DestinationPath %fileName%\
	ECHO Done!
	:UNZIPPED_FOLDER_ALREADY_EXISTS
	ECHO Folder %fileName% already exists. If you are sure it's incorrect, delete and restart this script.
	GOTO DOWNLOAD_AND_UNZIP_EXIT

	:DOWNLOAD_AND_UNZIP_EXIT
EXIT /B 0

:VERIFY_REG_EDIT
::WARNINGS!!
ECHO
ECHO I AM NOT RESPONSIBLE IF SOMETHING BREAKS.
ECHO PLEASE BACK UP YOUR REGISTRY FIRST.
ECHO PLEASE PLEASE PLEASE BACK IT UP.
::Y/N choice for reg update.
CHOICE /C:YN /T:10 /D:N /M:"Update Registry Key?"

IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 GOTO CALL_REG_EDIT
IF ERRORLEVEL 2 IF NOT ERRORLEVEL 3 GOTO SKIP_REG_EDIT

:SKIP_REG_EDIT
ECHO Skipping registry edit.
PAUSE
GOTO POST_REG_EDIT

:CALL_REG_EDIT
ECHO Updating registry values...
GOTO UPDATE_JDK_REGISTRY

:FUNC_UPDATE_REGISTRY_ENTRY
	::Storing parameters as variables.
	SET whichRegistryToSet=%~1	
	SET locationRegistryKey=%~2
	SET locationRegistryKeyData=%~3
	SET enabledRegistryKey=%~4
	
	ECHO %whichRegistryToSet%
	ECHO %locationRegistryKey%
	ECHO %locationRegistryKeyData%
	ECHO %enabledRegistryKey%

	PAUSE
	
	SET "hexOutput=Empty"
	CALL :FUNC_CONVERT_TO_HEX %locationRegistryKeyData% !hexOutput!
	ECHO %hexOutput%
	PAUSE
	
	:PERFORM_REG_EDIT
	ECHO Setting %whichRegistryToSet% related registry keys...
	
	ECHO Disabling the embedded location...
	ECHO REG ADD %REGISTRY_ENTRY_LOCATION% /v %enabledRegistryKey% /t REG_DWORD /d 0
	REG ADD %REGISTRY_ENTRY_LOCATION% /v %enabledRegistryKey% /t REG_DWORD /d 0
	PAUSE
	
	ECHO Updating the new directory in the registry...
	ECHO REG ADD %REGISTRY_ENTRY_LOCATION% /v %locationRegistryKey% /t REG_BINARY /d %hexOutput%
	REG ADD %REGISTRY_ENTRY_LOCATION% /v %locationRegistryKey% /t REG_BINARY /d %hexOutput%
	
	GOTO FUNC_UPDATE_REGISTRY_ENTRY_EXIT
	
	:SKIP_REG_EDIT
	ECHO Skipping registry edit!
	GOTO FUNC_UPDATE_REGISTRY_ENTRY_EXIT
	:FUNC_UPDATE_REGISTRY_ENTRY_EXIT	
EXIT /B 0

:UPDATE_JDK_REGISTRY
CHOICE /C:YN /T:10 /D:N /M:"Update JDK registry key?"
IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 CALL :FUNC_UPDATE_REGISTRY_ENTRY JDK %JDK_LOCATION_REGISTRY_KEY% %CD%/%JDK_FILE_NAME%/jdk-17.0.9 %JDK_ENABLED_REGISTRY_KEY%
IF ERRORLEVEL 2 IF NOT ERRORLEVEL 3 GOTO UPDATE_NDK_REGISTRY
	
:UPDATE_NDK_REGISTRY
CHOICE /C:YN /T:10 /D:N /M:"Update NDK registry key?"
IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 CALL :FUNC_UPDATE_REGISTRY_ENTRY NDK %NDK_LOCATION_REGISTRY_KEY% %CD%/%NDK_FILE_NAME%/android-ndk-r27c %NDK_ENABLED_REGISTRY_KEY%
IF ERRORLEVEL 2 IF NOT ERRORLEVEL 3 GOTO UPDATE_ASDK_REGISTRY

:UPDATE_ASDK_REGISTRY
CHOICE /C:YN /T:10 /D:N /M:"Update ASDK registry key?"
IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 CALL :FUNC_UPDATE_REGISTRY_ENTRY ASDK %ASDK_LOCATION_REGISTRY_KEY% %ASDK_LOCATION% %ASDK_ENABLED_REGISTRY_KEY%
IF ERRORLEVEL 2 IF NOT ERRORLEVEL 3 GOTO RETURN_REG_EDIT

:RETURN_REG_EDIT
GOTO POST_REG_EDIT

:POST_REG_EDIT
ECHO Past Reg Edit
GOTO VERIFY_TEMP_FOLDER

:VERIFY_TEMP_FOLDER
IF NOT EXIST temp\ (GOTO END_OF_PROGRAM)

::Y/N choice for reg update.
CHOICE /C:YN /T:10 /D:N /M:"Remove temporary download folder?"
IF ERRORLEVEL 1 IF NOT ERRORLEVEL 2 GOTO DELETE_TEMP_FOLDER
IF ERRORLEVEL 2 IF NOT ERRORLEVEL 3 GOTO END_OF_PROGRAM
:DELETE_TEMP_FOLDER
ECHO Double checking before deletion.
RMDIR /s temp\

:END_OF_PROGRAM
::Sleep for a few seconds.
ping 127.0.0.1 -n 2 -w 1000 > NUL
ping 127.0.0.1 -n %1 -w 1000 > NUL
PAUSE