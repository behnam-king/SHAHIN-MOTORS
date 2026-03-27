@echo off
setlocal
chcp 65001 >nul
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%~1"

echo ================================================
echo Shahin Motor - Auto Patch Apply and Run
echo ================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%installer.ps1" -ProjectRoot "%PROJECT_ROOT%"
set "EXITCODE=%ERRORLEVEL%"

echo.
if not "%EXITCODE%"=="0" (
    echo نصب خودکار کامل نشد. لاگ‌ها را در پوشه logs ببینید.
    echo اگر خواستید همان لاگ را برای من بفرستید تا پچ بعدی را دقیق‌تر بدهم.
    pause
    exit /b %EXITCODE%
)

echo کار تمام شد.
echo اگر مرورگر خودکار باز نشد، آدرس‌های زیر را امتحان کنید:
echo http://127.0.0.1:8000
echo http://127.0.0.1:8001
echo.
pause
exit /b 0
