@echo off
REM ===========================================================================
REM  Sudoku - build and sideload to a USB-connected Android device.
REM
REM  Usage:
REM    sideload.bat            Build a RELEASE apk and install it
REM    sideload.bat debug      Build a DEBUG apk and install it (faster)
REM
REM  Prereqs (one time):
REM    1. On the phone: Settings > About phone > tap "Build number" 7x to
REM       unlock Developer options.
REM    2. Settings > Developer options > enable "USB debugging".
REM    3. Plug the phone in over USB and tap "Allow" on the debugging prompt.
REM ===========================================================================
setlocal enabledelayedexpansion

set "APP_DIR=%~dp0app"

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

REM ---- find a connected, authorized device -------------------------------
adb start-server >nul 2>&1
set "DEVICE="
for /f "skip=1 tokens=1,2" %%a in ('adb devices') do (
  if "%%b"=="device" if not defined DEVICE set "DEVICE=%%a"
  if "%%b"=="unauthorized" echo [WARN] Device %%a is unauthorized - tap "Allow USB debugging" on the phone.
)

if not defined DEVICE (
  echo [ERROR] No authorized Android device found.
  echo         - Plug the phone in over USB.
  echo         - Enable USB debugging ^(see notes at top of this script^).
  echo         - Run 'adb devices' to confirm it shows 'device'.
  goto :fail
)
echo Target device: %DEVICE%
echo.

REM ---- build -------------------------------------------------------------
pushd "%APP_DIR%" || (echo [ERROR] Cannot find app folder: %APP_DIR% & goto :fail)

echo Building %MODE% APK ^(first build can take a few minutes^)...
if /I "%MODE%"=="release" (
  call flutter build apk --release
) else (
  call flutter build apk --debug
)
if errorlevel 1 (popd & echo [ERROR] Flutter build failed. & goto :fail)
popd

if not exist "%APK%" (echo [ERROR] APK not found at: %APK% & goto :fail)

REM ---- install -----------------------------------------------------------
echo.
echo Installing to %DEVICE%...
adb -s %DEVICE% install -r "%APK%"
if errorlevel 1 (
  echo [WARN] Reinstall failed ^(often a signature mismatch from a previous build^).
  echo        Uninstalling the old copy and retrying...
  adb -s %DEVICE% uninstall net.whimsicle.sudoku_app >nul 2>&1
  adb -s %DEVICE% install "%APK%"
  if errorlevel 1 (echo [ERROR] Install failed. & goto :fail)
)

REM ---- launch ------------------------------------------------------------
echo.
echo Launching app...
adb -s %DEVICE% shell monkey -p net.whimsicle.sudoku_app -c android.intent.category.LAUNCHER 1 >nul 2>&1

echo.
echo === Done. Sudoku (%MODE%) is installed on %DEVICE%. ===
echo APK: %APK%
echo.
pause
exit /b 0

:fail
echo.
echo === Sideload failed. ===
echo.
pause
exit /b 1
