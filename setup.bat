@echo off
chcp 65001 > nul
set TARGET=%USERPROFILE%\.claude\skills
if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /Y /I "%~dp0.claude\skills\*" "%TARGET%\" > nul
echo.
echo Done: skills copied to %TARGET%
echo.
pause