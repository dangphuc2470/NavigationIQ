@echo off
python "%~dp0build_garmin.py" beta %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build Beta failed!
    pause
    exit /b %ERRORLEVEL%
)
