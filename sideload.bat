@echo off
REM ===========================================================================
REM  Sudoku - build and sideload to EVERY connected Android device.
REM
REM  Usage:
REM    sideload.bat            Build a RELEASE apk and install to all devices
REM    sideload.bat debug      Build a DEBUG apk and install to all devices
REM
REM  Prereqs (one time, per phone):
REM    1. On the phone: Settings > About phone > tap "Build number" 7x to
REM       unlock Developer options.
REM    2. Settings > Developer options > enable "USB debugging".
REM    3. Plug the phone in over USB and tap "Allow" on the debugging prompt.
REM ===========================================================================
setlocal enabledelayedexpansion

set "APP_DIR=%~dp0app"
set "PKG=net.whimsicle.sudoku_app"

REM ---- mode --------------------------------------------------------------
set "MODE=release"
if /I "%~1"=="debug" set "MODE=debug"
if /I "%MODE%"=="release" (
  set "APK=%APP_DIR%\build\app\outputs\flutter-apk\app-release.apk"
) else (
  set "APK=%APP_DIR%\build\app\outputs\flutter-apk\app-debug.apk"
)

echo.
echo === Sudoku sideload (%MODE%) ===
echo.

REM ---- tool checks -------------------------------------------------------
where flutter >nul 2>&1 || (echo [ERROR] 'flutter' not found on PATH. & goto :fail)
where adb >nul 2>&1     || (echo [ERROR] 'adb' not found on PATH ^(install Android platform-tools^). & goto :fail)

REM ---- collect ALL connected, authorized devices -------------------------
adb start-server >nul 2>&1
set "DEVICES="
set "COUNT=0"
for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
  if "%%b"=="device" (
    set "DEVICES=!DEVICES! %%a"
    set /a COUNT+=1
  )
  if "%%b"=="unauthorized" echo [WARN] Device %%a is unauthorized - tap "Allow USB debugging" on it.
  if "%%b"=="offline"      echo [WARN] Device %%a is offline - reconnect it.
)

if %COUNT%==0 (
  echo [ERROR] No authorized Android devices found.
  echo         - Plug in one or more phones over USB ^(or start an emulator^).
  echo         - Enable USB debugging ^(see notes at top of this script^).
  echo         - Run 'adb devices' to confirm they show 'device'.
  goto :fail
)
echo Target devices ^(%COUNT%^):%DEVICES%
echo.

REM ---- build metadata (git commit + timestamp, shown in-app) -------------
set "GIT_SHA=unknown"
for /f "delims=" %%i in ('git -C "%~dp0." rev-parse --short HEAD 2^>nul') do set "GIT_SHA=%%i"
git -C "%~dp0." diff --quiet HEAD >nul 2>&1 || set "GIT_SHA=%GIT_SHA%+dirty"
set "BUILD_TIME=unknown"
for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm" 2^>nul') do set "BUILD_TIME=%%t"
echo Stamping build: %GIT_SHA% at %BUILD_TIME%

REM ---- build once --------------------------------------------------------
pushd "%APP_DIR%" || (echo [ERROR] Cannot find app folder: %APP_DIR% & goto :fail)
echo Building %MODE% APK ^(first build can take a few minutes^)...
if /I "%MODE%"=="release" (
  call flutter build apk --release --dart-define=GIT_SHA=%GIT_SHA% --dart-define=BUILD_TIME=%BUILD_TIME%
) else (
  call flutter build apk --debug --dart-define=GIT_SHA=%GIT_SHA% --dart-define=BUILD_TIME=%BUILD_TIME%
)
if errorlevel 1 (popd & echo [ERROR] Flutter build failed. & goto :fail)
popd

if not exist "%APK%" (echo [ERROR] APK not found at: %APK% & goto :fail)

REM ---- install to every device -------------------------------------------
set "OKLIST="
set "FAILLIST="
for %%d in (%DEVICES%) do call :install_one %%d

echo.
echo === Done (%MODE%). ===
if defined OKLIST  echo Installed on:%OKLIST%
if defined FAILLIST echo [WARN] Failed on:%FAILLIST%
echo APK: %APK%
echo.
pause
endlocal
exit /b 0

REM ---- subroutine: install + launch on one device ------------------------
:install_one
set "DEV=%~1"
echo.
echo --- %DEV% ---
adb -s %DEV% install -r "%APK%"
if errorlevel 1 (
  echo [WARN] Reinstall failed on %DEV% ^(often a signature mismatch^). Uninstalling and retrying...
  adb -s %DEV% uninstall %PKG% >nul 2>&1
  adb -s %DEV% install "%APK%"
  if errorlevel 1 (
    echo [ERROR] Install failed on %DEV%.
    set "FAILLIST=!FAILLIST! %DEV%"
    exit /b 0
  )
)
adb -s %DEV% shell monkey -p %PKG% -c android.intent.category.LAUNCHER 1 >nul 2>&1
echo   installed and launched on %DEV%
set "OKLIST=!OKLIST! %DEV%"
exit /b 0

:fail
echo.
echo === Sideload failed. ===
echo.
pause
endlocal
exit /b 1
