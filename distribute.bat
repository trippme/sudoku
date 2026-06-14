@echo off
REM ===========================================================================
REM  Sudoku - build a RELEASE APK and push it to Firebase App Distribution.
REM
REM  Sends the build to your testers (no Play Store / no review). They get an
REM  email + install via the "App Tester" app or a direct link.
REM
REM  Usage:
REM    distribute.bat                 sync + build + upload to group "tester"
REM    distribute.bat <group>         upload to a different tester group
REM    distribute.bat <group> --no-pull   skip the git sync (build local code)
REM
REM  Prereqs (one time):
REM    1. Firebase console > App Distribution > Get started (enable it).
REM    2. Add testers as a group. The default group alias here is "tester"
REM       (pass a different alias as the first arg to override).
REM    3. Firebase CLI installed + logged in:  npm i -g firebase-tools
REM                                            firebase login
REM ===========================================================================
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%app"
REM Firebase Android App ID (from app/android/app/google-services.json).
set "APP_ID=1:186440557207:android:cde025183a562c667e7fd2"
set "APK=%APP_DIR%\build\app\outputs\flutter-apk\app-release.apk"

REM ---- args (optional group + --no-pull) ---------------------------------
set "GROUP=tester"
set "PULL=1"
:parse
if "%~1"=="" goto parsed
if /I "%~1"=="--no-pull" (set "PULL=0") else (set "GROUP=%~1")
shift
goto parse
:parsed

echo.
echo === Sudoku - Firebase App Distribution (group: %GROUP%) ===
echo.

REM ---- tool checks -------------------------------------------------------
where flutter  >nul 2>&1 || (echo [ERROR] 'flutter' not found on PATH. & goto :fail)
where firebase >nul 2>&1 || (echo [ERROR] 'firebase' CLI not found ^(npm i -g firebase-tools ^&^& firebase login^). & goto :fail)

REM ---- 1. sync repo ------------------------------------------------------
if "%PULL%"=="0" goto :skipsync
where git >nul 2>&1 && (
  echo Syncing repo...
  git -C "%ROOT%." pull --ff-only
  if errorlevel 1 echo [WARN] git pull did not fast-forward - building CURRENT local code.
)
:skipsync

REM ---- 2. build metadata -------------------------------------------------
set "GIT_SHA=unknown"
for /f "delims=" %%i in ('git -C "%ROOT%." rev-parse --short HEAD 2^>nul') do set "GIT_SHA=%%i"
git -C "%ROOT%." diff --quiet HEAD >nul 2>&1 || set "GIT_SHA=%GIT_SHA%+dirty"
set "NOTES=%GIT_SHA%"
for /f "delims=" %%s in ('git -C "%ROOT%." log -1 "--pretty=%%s" 2^>nul') do set "NOTES=%%s (%GIT_SHA%)"
set "BUILD_TIME=unknown"
for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm" 2^>nul') do set "BUILD_TIME=%%t"
echo Building %GIT_SHA% at %BUILD_TIME%

REM ---- 3. build release APK ----------------------------------------------
pushd "%APP_DIR%" || (echo [ERROR] Cannot find app folder: %APP_DIR% & goto :fail)
echo Building release APK ^(first build can take a few minutes^)...
call flutter build apk --release --dart-define=GIT_SHA=%GIT_SHA% --dart-define=BUILD_TIME=%BUILD_TIME%
if errorlevel 1 (popd & echo [ERROR] Flutter build failed. & goto :fail)
popd
if not exist "%APK%" (echo [ERROR] APK not found at: %APK% & goto :fail)

REM ---- 4. upload to Firebase App Distribution ----------------------------
echo.
echo Uploading to Firebase App Distribution ^(group: %GROUP%^)...
call firebase appdistribution:distribute "%APK%" --app %APP_ID% --groups "%GROUP%" --release-notes "%NOTES%"
if errorlevel 1 (echo [ERROR] Distribution failed. & goto :fail)

echo.
echo === Distributed %GIT_SHA% to "%GROUP%". Testers will get an email. ===
echo.
pause
endlocal
exit /b 0

:fail
echo.
echo === Distribution failed. ===
echo.
pause
endlocal
exit /b 1
