@echo off

odin build src/ -out:odin-pong.exe -debug

if %errorlevel% neq 0 exit echo Build failed. && /b %errorlevel%

odin-pong.exe