@echo off
REM ===========================================================================
REM  Sudoku - COMPLETE build & deploy:
REM    1. sync the repo (git pull, so you build what you merged on GitHub)
REM    2. build the app (stamped with the commit + time)
REM    3. install + launch on EVERY connected Android device
REM
REM  Usage:
REM    deploy.bat            sync + RELEASE build + deploy to all devices
REM    deploy.bat debug      sync + DEBUG build + deploy (faster; keeps app data)
REM    deploy.bat --no-pull  skip the git sync (build your current local code)
REM
REM  Prereqs (one time, per phone):
REM    1. Settings > About phone > tap "Build number" 7x (unlocks Developer opts)
REM    2. Settings > Developer options > enable "USB debugging"
REM    3. Plug in over USB and tap "Allow" on the debugging prompt
REM
REM  Note: deploying the *server* (server/index.php to your web host) is separate
REM        - this script handles the app only.
REM ===========================================================================
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%app"
set "PKG=net.whimsicle.sudoku_app"

REM ---- args (mode + optional --no-pull) ----------------------------------
set "MODE=release"
set "PULL=1"
:parse
if "%~1"=="" goto parsed
if /I "%~1"=="debug"     set "MODE=debug"
if /I "%~1"=="release"   set "MODE=release"
if /I "%~1"=="--no-pull" set "PULL=0"
if /I "%~1"=="nopull"    set "PULL=0"
shift
goto parse
:parsed

if /I "%MODE%"=="release" (
  set "APK=%APP_DIR%\build\app\outputs\flutter-apk\app-release.apk"
) else (
  set "APK=%APP_DIR%\build\app\outputs\flutter-apk\app-debug.apk"
)

echo.
echo === Sudoku build ^& deploy (%MODE%) ===
echo.

REM ---- tool checks -------------------------------------------------------
where flutter >nul 2>&1 || (echo [ERROR] 'flutter' not found on PATH. & goto :fail)
where adb >nul 2>&1     || (echo [ERROR] 'adb' not found on PATH ^(install Android platform-tools^). & goto :fail)
where git >nul 2>&1     || (echo [WARN] 'git' not found - skipping repo sync. & set "PULL=0")

REM ---- 1. sync repo ------------------------------------------------------
if "%PULL%"=="0" goto :skipsync
echo Syncing repo with its upstream...
git -C "%ROOT%." pull --ff-only
if errorlevel 1 (
  echo [WARN] git pull did not fast-forward - building your CURRENT local code.
  echo        Commit/stash local changes, switch to main, or pass --no-pull.
)
for /f "delims=" %%c in ('git -C "%ROOT%." log -1 "--pretty=%%h %%s" 2^>nul') do echo On commit: %%c
echo.
:skipsync

REM ---- 2. collect ALL connected, authorized devices ----------------------
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

REM ---- 3. build metadata (git commit + timestamp, shown in-app) ----------
set "GIT_SHA=unknown"
for /f "delims=" %%i in ('git -C "%ROOT%." rev-parse --short HEAD 2^>nul') do set "GIT_SHA=%%i"
git -C "%ROOT%." diff --quiet HEAD >nul 2>&1 || set "GIT_SHA=%GIT_SHA%+dirty"
set "BUILD_TIME=unknown"
for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm" 2^>nul') do set "BUILD_TIME=%%t"
echo Stamping build: %GIT_SHA% at %BUILD_TIME%

REM ---- 4. build once -----------------------------------------------------
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

REM ---- 5. install + launch on every device -------------------------------
set "OKLIST="
set "FAILLIST="
for %%d in (%DEVICES%) do call :install_one %%d

echo.
echo === Done (%MODE%) @ %GIT_SHA%. ===
if defined OKLIST   echo Deployed to:%OKLIST%
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
  echo [WARN] Reinstall failed on %DEV% ^(usually a signing-key change^). Uninstalling and retrying...
  echo        ^(This resets the app's saved data on that device.^)
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
echo === Build ^& deploy failed. ===
echo.
pause
endlocal
exit /b 1
