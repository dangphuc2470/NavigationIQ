@echo off
python "%~dp0build_garmin.py" release %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build Release failed!
    pause
    exit /b %ERRORLEVEL%
)
