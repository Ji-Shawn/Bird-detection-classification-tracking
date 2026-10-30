@echo off
cd /d "%~dp0\..\.."
python -B -X utf8 board\tools\launch.py monitor
if errorlevel 1 pause
