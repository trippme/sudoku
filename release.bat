@echo off
REM ===========================================================================
REM  Sudoku - build a Play Store release AAB:
REM    1. sync the repo (git pull, so you build what you merged on GitHub)
REM    2. build the .aab, signed with the upload keystore, with:
REM         - versionCode = git commit count (auto-increments every merge,
REM           so Play never sees a reused versionCode)
REM         - the backend API key + commit/time stamp injected
REM
REM  Usage:
REM    release.bat            sync + build the release AAB
REM    release.bat --no-pull  skip the git sync (build your current local code)
REM
REM  Then upload the printed .aab in Play Console:
REM    Testing > Internal testing > Create new release
REM  (see docs\PLAY_STORE_BETA.md for the full walkthrough)
REM ===========================================================================
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
set "APP_DIR=%ROOT%app"
set "AAB=%APP_DIR%\build\app\outputs\bundle\release\app-release.aab"

REM ---- args (optional --no-pull) -----------------------------------------
set "PULL=1"
:parse
if "%~1"=="" goto parsed
if /I "%~1"=="--no-pull" set "PULL=0"
if /I "%~1"=="nopull"    set "PULL=0"
shift
goto parse
:parsed

echo.
echo === Sudoku Play Store release build ===
echo.

REM ---- tool checks -------------------------------------------------------
where flutter >nul 2>&1 || (echo [ERROR] 'flutter' not found on PATH. & goto :fail)
where git >nul 2>&1     || (echo [ERROR] 'git' not found on PATH ^(needed for the build number^). & goto :fail)

REM ---- release keystore check --------------------------------------------
if not exist "%APP_DIR%\android\key.properties" (
  echo [ERROR] app\android\key.properties not found - the AAB would be DEBUG-signed
  echo         and Play would reject it. See key.properties.example.
  goto :fail
)

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

REM ---- 2. build metadata -------------------------------------------------
REM versionCode = commit count: strictly grows with every merge, so each
REM upload automatically outranks the previous one. (Play requires a higher
REM versionCode on EVERY upload; versionName stays whatever pubspec.yaml says.)
set "BUILD_NUMBER="
for /f "delims=" %%n in ('git -C "%ROOT%." rev-list --count HEAD 2^>nul') do set "BUILD_NUMBER=%%n"
if not defined BUILD_NUMBER (echo [ERROR] Could not compute the git commit count. & goto :fail)

set "GIT_SHA=unknown"
for /f "delims=" %%i in ('git -C "%ROOT%." rev-parse --short HEAD 2^>nul') do set "GIT_SHA=%%i"
git -C "%ROOT%." diff --quiet HEAD >nul 2>&1 || set "GIT_SHA=%GIT_SHA%+dirty"
set "BUILD_TIME=unknown"
for /f "delims=" %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH:mm" 2^>nul') do set "BUILD_TIME=%%t"
echo Building versionCode %BUILD_NUMBER% ^(commit %GIT_SHA% at %BUILD_TIME%^)

REM Backend API key, injected so the app can talk to a key-protected server.
REM Read from server\data\api-key.txt (git-ignored); empty if absent.
set "BACKEND_API_KEY="
if exist "%ROOT%server\data\api-key.txt" set /p BACKEND_API_KEY=<"%ROOT%server\data\api-key.txt"
if not defined BACKEND_API_KEY (
  echo [WARN] server\data\api-key.txt not found - the app will not be able to
  echo        reach the key-protected backend ^(leaderboard/friends^).
)

REM ---- 3. build the AAB --------------------------------------------------
pushd "%APP_DIR%" || (echo [ERROR] Cannot find app folder: %APP_DIR% & goto :fail)
echo Building release AAB ^(first build can take a few minutes^)...
call flutter build appbundle --release --build-number=%BUILD_NUMBER% --dart-define=GIT_SHA=%GIT_SHA% --dart-define=BUILD_TIME=%BUILD_TIME% --dart-define=BACKEND_API_KEY=%BACKEND_API_KEY%
if errorlevel 1 (popd & echo [ERROR] Flutter build failed. & goto :fail)
popd

if not exist "%AAB%" (echo [ERROR] AAB not found at: %AAB% & goto :fail)

echo.
echo === Done. versionCode %BUILD_NUMBER% @ %GIT_SHA% ===
echo AAB: %AAB%
echo.
echo Next: Play Console ^> Testing ^> Internal testing ^> Create new release,
echo upload the AAB above, then roll out. ^(docs\PLAY_STORE_BETA.md^)
echo.
pause
endlocal
exit /b 0

:fail
echo.
echo === Release build failed. ===
echo.
pause
endlocal
exit /b 1
