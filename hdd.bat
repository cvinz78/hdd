@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Version 1.1
title cvinz78

rem ESC-Zeichen (0x1B) zuverlaessig ermitteln (siehe DESIGN.md)
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

rem Farbkonstanten (siehe DESIGN.md)
set "CYAN_H=%ESC%[1;96m"
set "YELLOW_H=%ESC%[1;93m"
set "RED_H=%ESC%[1;91m"
set "MAGENTA_L=%ESC%[1;35m"
set "GREEN_O=%ESC%[1;92m"
set "RESET=%ESC%[0m"

rem -nc-Modus: -nc aus den Argumenten herausfiltern und Farbvariablen
rem leeren (Fallback ohne Farben, z.B. bei Umleitung in eine Datei).
rem -nc ist kombinierbar, z.B. "hdd -nc -d C:" oder interaktiv "hdd -nc".
set "NC="
set /a ARGC=0
rem Hilfeoption-Sondernamen direkt erkennen: in for-Sets wird das
rem Fragezeichen als Wildcard behandelt und das Token wuerde
rem verschluckt (0 Iterationen). Gilt fuer Position 1 und 2.
if "%~1"=="/?" set "SWITCHHELP=1"
if "%~2"=="/?" set "SWITCHHELP=1"
for %%A in (%*) do (
    if /I "%%~A"=="-nc" (
        set "NC=1"
    ) else (
        set /a ARGC+=1
        set "ARG!ARGC!=%%~A"
    )
)
if defined SWITCHHELP (
    set /a ARGC+=1
    set "ARG!ARGC!=/?"
)
if defined NC (
    set "CYAN_H="
    set "YELLOW_H="
    set "RED_H="
    set "MAGENTA_L="
    set "GREEN_O="
    set "RESET="
)

rem Argumentmodus-Kennzeichnung (leer = interaktiver Modus)
set "ARGMODE="
if %ARGC% GTR 0 set "ARGMODE=1"

:: --- Auto-Admin (gilt fuer beide Modi) ---
net session >nul 2>&1
if !errorlevel! equ 0 goto ADMIN_OK
echo !RED_H!WARNUNG: Administratorrechte werden benoetigt.!RESET!
echo !YELLOW_H!Starte cmd.exe mit Administratorrechten und rufe das Skript erneut auf...!RESET!
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process cmd.exe -Verb RunAs -ArgumentList '/s /c \"\"%~f0\" %*\"'"
exit /b
:ADMIN_OK

if defined ARGMODE goto PARSEARGS

:: ==================================================================
:: Interaktiver Modus
:: ==================================================================
:MENU
cls
echo %CYAN_H%# cvinz78%RESET%
echo %YELLOW_H%==============================================%RESET%
echo.
echo %GREEN_O% 1%RESET%  Festplatten defragmentieren
echo %GREEN_O% 2%RESET%  Festplatte auf Fehler ueberpruefen und reparieren
echo %GREEN_O% 3%RESET%  SSD Trim durchfuehren
echo %GREEN_O% 4%RESET%  Diskpart starten (Partitionsverwaltung)
echo %GREEN_O% 5%RESET%  System neustarten oder herunterfahren
echo.
echo %RED_H% 00%RESET%  Beenden
echo.
set "choice="
set /p "choice=%CYAN_H%Auswahl:%RESET% "
rem Normalisierung: entfernt CR/Zeilenumbrueche bei umgeleiteter Eingabe
for /F "delims=" %%A in ("!choice!") do set "choice=%%A"
if not defined choice goto MENU
if "!choice!"=="0" goto MENU
if "!choice!"=="00" goto ENDE
if "!choice!"=="1" goto DEFRAG
if "!choice!"=="2" goto CHKDSK
if "!choice!"=="3" goto TRIM
if "!choice!"=="4" goto DISKPART
if "!choice!"=="5" goto POWER

echo %RED_H%Ungueltige Auswahl:%RESET% %YELLOW_H%!choice!%RESET%
ping -n 3 127.0.0.1 >nul
goto MENU

:GETDRIVES
set "DRIVES="
for /f "delims=" %%D in ('powershell -NoProfile -Command "(Get-CimInstance Win32_LogicalDisk).DeviceID"') do set "DRIVES=!DRIVES! %%D"
exit /b

:DEFRAG
cls
call :GETDRIVES
echo %CYAN_H%# Festplatten defragmentieren%RESET%
echo.
echo %YELLOW_H%Verfuegbare Laufwerke:%RESET%!DRIVES!
echo.
set "dfdrive="
set /p "dfdrive=%CYAN_H%Welches Laufwerk defragmentieren? (z.B. C: / 0=Zurueck):%RESET% "
for /F "delims=" %%A in ("!dfdrive!") do set "dfdrive=%%A"
if not defined dfdrive goto MENU
if "!dfdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!dfdrive!"
if errorlevel 1 goto MENU
:DO_DEFRAG
echo.
echo %MAGENTA_L%Befehl: defrag !DRV! /U /V%RESET%
echo.
defrag !DRV! /U /V
set "LASTRC=!errorlevel!"
echo.
call :STATUS
if defined ARGMODE exit /b !LASTRC!
echo.
pause
goto MENU

:CHKDSK
cls
call :GETDRIVES
echo %CYAN_H%# Festplatte auf Fehler ueberpruefen und reparieren%RESET%
echo.
echo %YELLOW_H%Verfuegbare Laufwerke:%RESET%!DRIVES!
echo.
set "ckdrive="
set /p "ckdrive=%CYAN_H%Welches Laufwerk pruefen/reparieren? (z.B. C: / 0=Zurueck):%RESET% "
for /F "delims=" %%A in ("!ckdrive!") do set "ckdrive=%%A"
if not defined ckdrive goto MENU
if "!ckdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!ckdrive!"
if errorlevel 1 goto MENU
:DO_CHKDSK
echo.
if /i "!DRV!"=="C:" (
    echo !YELLOW_H!Systemlaufwerk erkannt.!RESET!
    echo !YELLOW_H!CHKDSK /f wird beim naechsten Neustart eingeplant,!RESET!
    echo !YELLOW_H!falls das Laufwerk nicht gesperrt werden kann.!RESET%
    echo.
    echo !MAGENTA_L!Befehl: chkdsk !DRV! /f!RESET!
    echo.
    chkdsk !DRV! /f
    set "LASTRC=!errorlevel!"
    echo.
    call :STATUS
    echo.
    echo !YELLOW_H!Falls Windows fragt, ob die Pruefung beim Neustart!RESET!
    echo !YELLOW_H!ausgefuehrt werden soll, mit J bestaetigen.!RESET!
) else (
    echo !MAGENTA_L!Befehl: chkdsk !DRV! /f!RESET!
    echo.
    chkdsk !DRV! /f
    set "LASTRC=!errorlevel!"
    echo.
    call :STATUS
)

if defined ARGMODE exit /b !LASTRC!
echo.
pause
goto MENU

:TRIM
cls
call :GETDRIVES
echo %CYAN_H%# SSD Trim durchfuehren%RESET%
echo.
echo %YELLOW_H%Verfuegbare Laufwerke:%RESET%!DRIVES!
echo.
set "trimdrive="
set /p "trimdrive=%CYAN_H%Welches Laufwerk trimmen? (z.B. C: / 0=Zurueck):%RESET% "
for /F "delims=" %%A in ("!trimdrive!") do set "trimdrive=%%A"
if not defined trimdrive goto MENU
if "!trimdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!trimdrive!"
if errorlevel 1 goto MENU
:DO_TRIM
echo.
echo %MAGENTA_L%Befehl: Optimize-Volume -DriveLetter !DRV! -ReTrim -Verbose%RESET%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Optimize-Volume -DriveLetter '!DRV:~0,1!' -ReTrim -Verbose"
set "LASTRC=!errorlevel!"
echo.
call :STATUS
if defined ARGMODE exit /b !LASTRC!
echo.
pause
goto MENU

:DISKPART
cls
echo %CYAN_H%# Diskpart - Partitionsverwaltung%RESET%
echo.
echo %YELLOW_H%Hinweis: Diskpart arbeitet direkt auf den Datentraegern -!RESET%
echo %YELLOW_H%Befehle sorgfaeltig pruefen (list disk, sel disk, ...).!RESET%
echo %YELLOW_H%Mit "exit" verlaesst man Diskpart und kehrt ins Menue zurueck.!RESET%
echo.
echo %MAGENTA_L%Befehl: diskpart%RESET%
echo.
diskpart
set "LASTRC=!errorlevel!"
echo.
call :STATUS
echo.
pause
goto MENU

:POWER
cls
echo %CYAN_H%# System neustarten oder herunterfahren%RESET%
echo.
echo %GREEN_O% 1%RESET%  Neustarten
echo %GREEN_O% 2%RESET%  Herunterfahren
echo.
echo %YELLOW_H% 0%RESET%  Zurueck
echo.
set "pchoice="
set /p "pchoice=%CYAN_H%Auswahl:%RESET% "
for /F "delims=" %%A in ("!pchoice!") do set "pchoice=%%A"
if not defined pchoice goto MENU
if "!pchoice!"=="0" goto MENU
if "!pchoice!"=="1" goto RESTART
if "!pchoice!"=="2" goto SHUTDOWN

echo %RED_H%Ungueltige Auswahl:%RESET% %YELLOW_H%!pchoice!%RESET%
ping -n 3 127.0.0.1 >nul
goto POWER

:RESTART
echo %RED_H%WARNUNG: Das System wird jetzt neu gestartet.%RESET%
shutdown /r /t 0
exit /b 0

:SHUTDOWN
echo %RED_H%WARNUNG: Das System wird jetzt heruntergefahren.%RESET%
shutdown /s /t 0
exit /b 0

:STATUS
rem Zeigt das Ergebnis des letzten Befehls an (LASTRC vorher setzen)
if "!LASTRC!"=="0" (
    echo !GREEN_O!Befehl erfolgreich beendet.!RESET!
) else (
    echo !RED_H!Befehl beendet mit Exitcode !LASTRC!.!RESET!
)
exit /b

:ENDE
exit /b 0

:: ==================================================================
:: Argumentmodus: hdd -d C: / -c C: / -t C: / -r / -s / -h / --help / /?
:: -nc schaltet die Farben ab (kombinierbar, z.B. hdd -nc -d C:).
:: Keine Rueckfragen, kein pause; Exitcode des Befehls wird
:: als Exitcode des Skripts zurueckgegeben.
:: ==================================================================
:PARSEARGS
set "SWITCH=!ARG1!"
set "DRIVE="
if %ARGC% GTR 1 set "DRIVE=!ARG2!"

if /i "!SWITCH!"=="/?" goto USAGE
if /i "!SWITCH!"=="-h" goto USAGE
if /i "!SWITCH!"=="--help" goto USAGE
if /i "!DRIVE!"=="/?" goto USAGE
if /i "!SWITCH!"=="-d" goto ARG_DEF
if /i "!SWITCH!"=="-c" goto ARG_CHK
if /i "!SWITCH!"=="-t" goto ARG_TRIM
if /i "!SWITCH!"=="-r" goto RESTART
if /i "!SWITCH!"=="-s" goto SHUTDOWN
if /i "!SWITCH!"=="-h" goto USAGE
if /i "!SWITCH!"=="--help" goto USAGE

echo %RED_H%Unbekanntes Argument:%RESET% %YELLOW_H%!SWITCH!%RESET%
goto USAGE_FAIL

:ARG_DEF
call :VALIDATE_DRIVE "!DRIVE!"
if errorlevel 1 exit /b 1
goto DO_DEFRAG

:ARG_CHK
call :VALIDATE_DRIVE "!DRIVE!"
if errorlevel 1 exit /b 1
goto DO_CHKDSK

:ARG_TRIM
call :VALIDATE_DRIVE "!DRIVE!"
if errorlevel 1 exit /b 1
goto DO_TRIM

:VALIDATE_DRIVE
rem %1 = Eingabe (z.B. "C:", "c", "C:\"); setzt !DRV! (z.B. "C:")
if "%~1"=="" (
    echo !RED_H!Kein Laufwerk angegeben.!RESET!
    echo !YELLOW_H!Beispiel: hdd -d C:!RESET!
    exit /b 1
)
set "DRV=%~1"
set "DRV=!DRV:~0,1!:"
if not exist "!DRV!\" (
    echo %RED_H%Laufwerk !DRV! nicht gefunden.%RESET%
    exit /b 1
)
exit /b 0

:USAGE
echo %CYAN_H%# cvinz78%RESET%
echo %YELLOW_H%  hdd -d C:%RESET%   Festplatte defragmentieren
echo %YELLOW_H%  hdd -c C:%RESET%   Auf Fehler pruefen und reparieren (chkdsk /f)
echo %YELLOW_H%  hdd -t C:%RESET%   SSD Trim durchfuehren
echo %YELLOW_H%  hdd -r%RESET%      System neustarten
echo %YELLOW_H%  hdd -s%RESET%      System herunterfahren
echo %YELLOW_H%  hdd -nc%RESET%     Farben deaktivieren (kombinierbar, z.B. hdd -nc -d C:)
echo %YELLOW_H%  hdd -h / --help / /?%RESET%   Diese Hilfe anzeigen
echo.
echo %YELLOW_H%Ohne Argumente startet der interaktive Modus.%RESET%
exit /b 0

:USAGE_FAIL
echo.
call :USAGE
exit /b 1
