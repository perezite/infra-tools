@echo off

rem ## Globals
SET repositoryUrl=%1%
SET repositoryFolder=repo

:Main 
	rem ## show help if not enough arguments specified
	IF [%2]==[] (
		echo usage:   BackupGitRepo.bat ^<Repo-Ulr^> ^<Target-7zip-Archive-File-Path^>
		echo example: BackupGitRepo.bat https://github.com/user/repo d:\backup\archive.7z
		exit /b
	)

	rem ## Initialization
	SET basePath=%~dp0

	rem ## Checkout
	echo Checkout ...
	rem git clone --bare %repositoryUrl% %repositoryFolder% > nul 
	call :SubGitClone
	
	rem ## Zip
	echo Compress ...
	SET zipArchive=%repositoryFolder%.7z
	7za.exe a -r %zipArchive% %repositoryFolder% > nul
	rmdir /S /Q %repositoryFolder%

	rem ## Move
	echo Copy to target ...
	SET targetPath=%~dp2
	SET targetPath=%targetPath:~0,-1%
	if not exist %targetPath% (
		mkdir %targetPath%
	)
	copy %zipArchive% %2
	del /f %zipArchive%
	
	rem ## Verify
	echo Verify ...
	SET targetFile=%~nx2
	SET verificationUnzipFolder=verify
	SET SevenZipExecutable=%~dp07za.exe 
	cd /D %targetPath%
	rem ## echo target: %targetPath%
	rem ## echo actual: %cd%
	%SevenZipExecutable% x -r -o%verificationUnzipFolder% %targetFile% > nul
	cd /D %verificationUnzipFolder%\%repositoryFolder% > nul
	git fsck > nul
	IF %errorlevel% NEQ 0 (
		cd /D ..\..
		rmdir /S /Q %verificationUnzipFolder%
		del /f %targetFile%
		cd /D %~dp0
		exit /b
	)
	cd /D ..\..
	rmdir /S /Q %verificationUnzipFolder%
	cd /D %~dp0

	GOTO :End
:EndMain

:SubGitClone
	:GitAuthenticationLoop
		git clone --bare %repositoryUrl% %repositoryFolder% > nul
		IF %errorlevel% EQU 0 (
			GOTO :GitAuthenticationLoopEnd
		)
		GOTO :GitAuthenticationLoop
	:GitAuthenticationLoopEnd
	
	GOTO :eof

:SubGitCloneEnd

:End

