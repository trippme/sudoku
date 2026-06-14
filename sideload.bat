@echo off
REM ===========================================================================
REM  Sudoku - build & install to all connected Android devices.
REM
REM  This now SYNCS FIRST (git pull) then builds + deploys, so you never ship
REM  stale code by accident. It's just a familiar-named pass-through to
REM  deploy.bat - they do the same thing.
REM
REM  Usage:
REM    sideload.bat            sync + RELEASE build + install to all devices
REM    sideload.bat debug      sync + DEBUG build + install to all devices
REM    sideload.bat --no-pull  build your CURRENT local code (skip the git sync)
REM ===========================================================================
call "%~dp0deploy.bat" %*
