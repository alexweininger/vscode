@echo off
setlocal

pushd %~dp0\..

set VSCODEUSERDATADIR=%TEMP%\vscodeuserfolder-%RANDOM%-%TIME:~6,2%
set VSCODECRASHDIR=%~dp0\..\.build\crashes

:: Figure out which Electron to use for running tests
if "%INTEGRATION_TEST_ELECTRON_PATH%"=="" (
	:: Run out of sources: no need to compile as code.bat takes care of it
	chcp 65001
	set INTEGRATION_TEST_ELECTRON_PATH=.\scripts\code.bat
	set VSCODE_BUILD_BUILTIN_EXTENSIONS_SILENCE_PLEASE=1

	echo Storing crash reports into '%VSCODECRASHDIR%'.
	echo Running integration tests out of sources.
) else (
	:: Run from a built: need to compile all test extensions
	:: because we run extension tests from their source folders
	:: and the build bundles extensions into .build webpacked
	call yarn gulp 	compile-extension:vscode-api-tests^
					compile-extension:vscode-colorize-tests^
					compile-extension:markdown-language-features^
					compile-extension:typescript-language-features^
					compile-extension:vscode-custom-editor-tests^
					compile-extension:vscode-notebook-tests^
					compile-extension:emmet^
					compile-extension:css-language-features-server^
					compile-extension:html-language-features-server^
					compile-extension:json-language-features-server^
					compile-extension:git

	:: Configuration for more verbose output
	set VSCODE_CLI=1
	set ELECTRON_ENABLE_LOGGING=1

	echo Storing crash reports into '%VSCODECRASHDIR%'.
	echo Running integration tests with '%INTEGRATION_TEST_ELECTRON_PATH%' as build.
)

:: Integration & performance tests in AMD
@REM ::call .\scripts\test.bat --runGlob **\*.integrationTest.js %*
@REM ::if %errorlevel% neq 0 exit /b %errorlevel%

:: Tests in the extension host

call "%INTEGRATION_TEST_ELECTRON_PATH%" $%~dp0\..\extensions\emmet\out\test\test-fixtures --extensionDevelopmentPath=%~dp0\..\extensions\emmet --extensionTestsPath=%~dp0\..\extensions\emmet\out\test --disable-telemetry --crash-reporter-directory=%VSCODECRASHDIR% --no-cached-data --disable-updates --disable-extensions --user-data-dir=%VSCODEUSERDATADIR% .
if %errorlevel% neq 0 exit /b %errorlevel%

rmdir /s /q %VSCODEUSERDATADIR%

popd

endlocal
