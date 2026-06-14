@echo off
REM ===========================================================================
REM  Sudoku - build & install WITHOUT syncing the repo first.
REM  This is just deploy.bat with the git pull skipped. For the full
REM  "sync + build + deploy" flow (recommended), use deploy.bat.
REM
REM  Usage:
REM    sideload.bat          RELEASE build + install to all devices (no git pull)
REM    sideload.bat debug    DEBUG build + install to all devices  (no git pull)
REM ===========================================================================
call "%~dp0deploy.bat" %* --no-pull
