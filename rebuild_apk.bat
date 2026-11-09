@echo off
setlocal
cd /d "%~dp0"
call flutter build apk --release
if errorlevel 1 exit /b %errorlevel%
copy /y "build\app\outputs\flutter-apk\app-release.apk" "D:\gamz.apk" >nul
if errorlevel 1 exit /b %errorlevel%
echo APK berhasil dibuat: D:\gamz.apk
endlocal
