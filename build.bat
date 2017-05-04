@ECHO OFF
CLS
ECHO -Building...
CD src
fasm bootloader.asm ../build/bootloader.img
if %ERRORLEVEL% EQU 0 GOTO DONE
CD ..
ECHO -Building failed! (ERR)
GOTO :EXIT
:DONE
CD ..
set /p Build=<version.txt
set /a Build=%Build%+1
>version.txt echo %Build%
echo -Building complete! (build:%Build%)
:EXIT
@ECHO ON
