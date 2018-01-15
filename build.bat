@echo off
rem	Build script for SamplePlayer

rem	Build ROM
echo Assembling...
rgbasm -o SamplePlayer.obj -p 255 Main.asm
if errorlevel 1 goto :BuildError
echo Linking...
rgblink -p 255 -o SamplePlayer.gb -n SamplePlayer.sym SamplePlayer.obj
if errorlevel 1 goto :BuildError
echo Fixing...
rgbfix -v -p 255 SamplePlayer.gb
echo Build complete.
rem Clean up files
del SamplePlayer.obj
goto:eof

:BuildError
echo Build failed, aborting...