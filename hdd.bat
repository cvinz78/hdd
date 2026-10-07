@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Version 1.2
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
rem -de/-en erzwingen die Sprache und werden ebenso herausgefiltert.
rem Alle Schalter sind kombinierbar, z.B. "hdd -nc -en -d C:" oder
rem interaktiv "hdd -en".
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
    ) else if /I "%%~A"=="-de" (
        set "FORCEDLANG=de"
    ) else if /I "%%~A"=="-en" (
        set "FORCEDLANG=en"
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

rem Sprachauswahl: -de/-en erzwingen die Sprache, sonst wird die
rem Windows-Anzeigesprache erkannt (Get-UICulture). Fehlt die
rem Erkennung (z.B. ohne PowerShell), bleibt Deutsch als Fallback.
set "LANG=de"
if defined FORCEDLANG (
    if /I "!FORCEDLANG!"=="en" set "LANG=en"
) else (
    for /f "delims=" %%L in ('powershell -NoProfile -Command "(Get-UICulture).TwoLetterISOLanguageName" 2^>nul') do (
        if /I not "%%L"=="de" set "LANG=en"
    )
)
if "!LANG!"=="en" (call :LANG_EN) else (call :LANG_DE)

rem Argumentmodus-Kennzeichnung (leer = interaktiver Modus)
set "ARGMODE="
if %ARGC% GTR 0 set "ARGMODE=1"

:: --- Auto-Admin (gilt fuer beide Modi) ---
net session >nul 2>&1
if !errorlevel! equ 0 goto ADMIN_OK
echo !RED_H!!L_WARN_ADMIN!!RESET!
echo !YELLOW_H!!L_ELEVATE!!RESET!
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
echo %GREEN_O% 1%RESET%  !L_SEC_DEFRAG!
echo %GREEN_O% 2%RESET%  !L_SEC_CHK!
echo %GREEN_O% 3%RESET%  !L_SEC_TRIM!
echo %GREEN_O% 4%RESET%  !L_M_DISKPART!
echo %GREEN_O% 5%RESET%  !L_SEC_POWER!
echo.
echo %RED_H% 00%RESET%  !L_M_QUIT!
echo.
set "choice="
set /p "choice=%CYAN_H%!L_PROMPT!%RESET% "
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

echo %RED_H%!L_INVALID!%RESET% %YELLOW_H%!choice!%RESET%
ping -n 3 127.0.0.1 >nul
goto MENU

:GETDRIVES
set "DRIVES="
for /f "delims=" %%D in ('powershell -NoProfile -Command "(Get-CimInstance Win32_LogicalDisk).DeviceID"') do set "DRIVES=!DRIVES! %%D"
exit /b

:DEFRAG
cls
call :GETDRIVES
echo %CYAN_H%# !L_SEC_DEFRAG!%RESET%
echo.
echo %YELLOW_H%!L_DRIVES!%RESET%!DRIVES!
echo.
set "dfdrive="
set /p "dfdrive=%CYAN_H%!L_ASK_DEFRAG!%RESET% "
for /F "delims=" %%A in ("!dfdrive!") do set "dfdrive=%%A"
if not defined dfdrive goto MENU
if "!dfdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!dfdrive!"
if errorlevel 1 goto MENU
:DO_DEFRAG
echo.
echo %MAGENTA_L%!L_CMD! defrag !DRV! /U /V%RESET%
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
echo %CYAN_H%# !L_SEC_CHK!%RESET%
echo.
echo %YELLOW_H%!L_DRIVES!%RESET%!DRIVES!
echo.
set "ckdrive="
set /p "ckdrive=%CYAN_H%!L_ASK_CHK!%RESET% "
for /F "delims=" %%A in ("!ckdrive!") do set "ckdrive=%%A"
if not defined ckdrive goto MENU
if "!ckdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!ckdrive!"
if errorlevel 1 goto MENU
:DO_CHKDSK
echo.
if /i "!DRV!"=="C:" (
    echo !YELLOW_H!!L_SYSDEV1!!RESET!
    echo !YELLOW_H!!L_SYSDEV2!!RESET!
    echo !YELLOW_H!!L_SYSDEV3!!RESET!
    echo.
    echo !MAGENTA_L!!L_CMD! chkdsk !DRV! /f!RESET!
    echo.
    chkdsk !DRV! /f
    set "LASTRC=!errorlevel!"
    echo.
    call :STATUS
    echo.
    echo !YELLOW_H!!L_CONFIRM1!!RESET!
    echo !YELLOW_H!!L_CONFIRM2!!RESET!
) else (
    echo !MAGENTA_L!!L_CMD! chkdsk !DRV! /f!RESET!
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
echo %CYAN_H%# !L_SEC_TRIM!%RESET%
echo.
echo %YELLOW_H%!L_DRIVES!%RESET%!DRIVES!
echo.
set "trimdrive="
set /p "trimdrive=%CYAN_H%!L_ASK_TRIM!%RESET% "
for /F "delims=" %%A in ("!trimdrive!") do set "trimdrive=%%A"
if not defined trimdrive goto MENU
if "!trimdrive!"=="0" goto MENU
call :VALIDATE_DRIVE "!trimdrive!"
if errorlevel 1 goto MENU
:DO_TRIM
echo.
echo %MAGENTA_L%!L_CMD! Optimize-Volume -DriveLetter !DRV! -ReTrim -Verbose%RESET%
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
echo %CYAN_H%# !L_SEC_DISKPART!%RESET%
echo.
echo %YELLOW_H%!L_DP1!!RESET!
echo %YELLOW_H%!L_DP2!!RESET!
echo %YELLOW_H%!L_DP3!!RESET!
echo.
echo %MAGENTA_L%!L_CMD! diskpart%RESET%
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
echo %CYAN_H%# !L_SEC_POWER!%RESET%
echo.
echo %GREEN_O% 1%RESET%  !L_PM1!
echo %GREEN_O% 2%RESET%  !L_PM2!
echo.
echo %YELLOW_H% 0%RESET%  !L_P0!
echo.
set "pchoice="
set /p "pchoice=%CYAN_H%!L_PROMPT!%RESET% "
for /F "delims=" %%A in ("!pchoice!") do set "pchoice=%%A"
if not defined pchoice goto MENU
if "!pchoice!"=="0" goto MENU
if "!pchoice!"=="1" goto RESTART
if "!pchoice!"=="2" goto SHUTDOWN

echo %RED_H%!L_INVALID!%RESET% %YELLOW_H%!pchoice!%RESET%
ping -n 3 127.0.0.1 >nul
goto POWER

:RESTART
echo %RED_H%!L_WARN_R!%RESET%
shutdown /r /t 0
exit /b 0

:SHUTDOWN
echo %RED_H%!L_WARN_S!%RESET%
shutdown /s /t 0
exit /b 0

:STATUS
rem Zeigt das Ergebnis des letzten Befehls an (LASTRC vorher setzen)
if "!LASTRC!"=="0" (
    echo !GREEN_O!!L_ST_OK!!RESET!
) else (
    echo !RED_H!!L_ST_FAIL! !LASTRC!.!RESET!
)
exit /b

:ENDE
exit /b 0

:: ==================================================================
:: Argumentmodus: hdd -d C: / -c C: / -t C: / -r / -s / -h / --help / /?
:: -nc schaltet die Farben ab, -de/-en erzwingen die Sprache
:: (kombinierbar, z.B. hdd -nc -en -d C:).
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

echo %RED_H%!L_UNKNOWN!%RESET% %YELLOW_H%!SWITCH!%RESET%
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
    echo !RED_H!!L_NODRIVE!!RESET!
    echo !YELLOW_H!!L_EXAMPLE!!RESET!
    exit /b 1
)
set "DRV=%~1"
set "DRV=!DRV:~0,1!:"
if not exist "!DRV!\" (
    echo !RED_H!!L_NF_PRE! !DRV! !L_NF_SUF!!RESET!
    exit /b 1
)
exit /b 0

:USAGE
echo %CYAN_H%# cvinz78%RESET%
echo %YELLOW_H%  hdd -d C:%RESET%   !L_U_D!
echo %YELLOW_H%  hdd -c C:%RESET%   !L_U_C!
echo %YELLOW_H%  hdd -t C:%RESET%   !L_U_T!
echo %YELLOW_H%  hdd -r%RESET%      !L_U_R!
echo %YELLOW_H%  hdd -s%RESET%      !L_U_S!
echo %YELLOW_H%  hdd -nc%RESET%     !L_U_NC!
echo %YELLOW_H%  hdd -de%RESET%     !L_U_DE!
echo %YELLOW_H%  hdd -en%RESET%     !L_U_EN!
echo %YELLOW_H%  hdd -h / --help / /?%RESET%   !L_U_H!
echo.
echo %YELLOW_H%!L_U_NOARG!!RESET%
exit /b 0

:USAGE_FAIL
echo.
call :USAGE
exit /b 1

:: ==================================================================
:: Sprachtexte: alle Ausgaben als Variablen, damit das Skript auf
:: deutschen und englischen Windows-Systemen funktioniert. Die
:: deutschen Texte nutzen "ue/oe/ae"-Schreibweise (codepage-sicher).
:: ==================================================================
:LANG_DE
set "L_WARN_ADMIN=WARNUNG: Administratorrechte werden benoetigt."
set "L_ELEVATE=Starte cmd.exe mit Administratorrechten und rufe das Skript erneut auf..."
set "L_INVALID=Ungueltige Auswahl:"
set "L_PROMPT=Auswahl:"
set "L_DRIVES=Verfuegbare Laufwerke:"
set "L_CMD=Befehl:"
set "L_SEC_DEFRAG=Festplatten defragmentieren"
set "L_SEC_CHK=Festplatte auf Fehler ueberpruefen und reparieren"
set "L_SEC_TRIM=SSD Trim durchfuehren"
set "L_SEC_DISKPART=Diskpart - Partitionsverwaltung"
set "L_SEC_POWER=System neustarten oder herunterfahren"
set "L_M_DISKPART=Diskpart starten (Partitionsverwaltung)"
set "L_M_QUIT=Beenden"
set "L_ASK_DEFRAG=Welches Laufwerk defragmentieren? (z.B. C: / 0=Zurueck):"
set "L_ASK_CHK=Welches Laufwerk pruefen/reparieren? (z.B. C: / 0=Zurueck):"
set "L_ASK_TRIM=Welches Laufwerk trimmen? (z.B. C: / 0=Zurueck):"
set "L_SYSDEV1=Systemlaufwerk erkannt."
set "L_SYSDEV2=CHKDSK /f wird beim naechsten Neustart eingeplant,"
set "L_SYSDEV3=falls das Laufwerk nicht gesperrt werden kann."
set "L_CONFIRM1=Falls Windows fragt, ob die Pruefung beim Neustart"
set "L_CONFIRM2=ausgefuehrt werden soll, mit J bestaetigen."
set "L_DP1=Hinweis: Diskpart arbeitet direkt auf den Datentraegern -"
set "L_DP2=Befehle sorgfaeltig pruefen (list disk, sel disk, ...)."
set "L_DP3=Mit "exit" verlaesst man Diskpart und kehrt ins Menue zurueck."
set "L_PM1=Neustarten"
set "L_PM2=Herunterfahren"
set "L_P0=Zurueck"
set "L_WARN_R=WARNUNG: Das System wird jetzt neu gestartet."
set "L_WARN_S=WARNUNG: Das System wird jetzt heruntergefahren."
set "L_ST_OK=Befehl erfolgreich beendet."
set "L_ST_FAIL=Befehl beendet mit Exitcode"
set "L_NODRIVE=Kein Laufwerk angegeben."
set "L_EXAMPLE=Beispiel: hdd -d C:"
set "L_NF_PRE=Laufwerk"
set "L_NF_SUF=nicht gefunden."
set "L_UNKNOWN=Unbekanntes Argument:"
set "L_U_D=Festplatte defragmentieren"
set "L_U_C=Auf Fehler pruefen und reparieren (chkdsk /f)"
set "L_U_T=SSD Trim durchfuehren"
set "L_U_R=System neustarten"
set "L_U_S=System herunterfahren"
set "L_U_NC=Farben deaktivieren (kombinierbar, z.B. hdd -nc -d C:)"
set "L_U_DE=Deutsch erzwingen (kombinierbar, z.B. hdd -de -d C:)"
set "L_U_EN=Englisch erzwingen (kombinierbar, z.B. hdd -en -d C:)"
set "L_U_H=Diese Hilfe anzeigen"
set "L_U_NOARG=Ohne Argumente startet der interaktive Modus."
exit /b

:LANG_EN
set "L_WARN_ADMIN=WARNING: Administrator privileges are required."
set "L_ELEVATE=Starting cmd.exe with administrator privileges and re-running the script..."
set "L_INVALID=Invalid selection:"
set "L_PROMPT=Selection:"
set "L_DRIVES=Available drives:"
set "L_CMD=Command:"
set "L_SEC_DEFRAG=Defragment hard drives"
set "L_SEC_CHK=Check hard drive for errors and repair"
set "L_SEC_TRIM=Perform SSD trim"
set "L_SEC_DISKPART=Diskpart - Partition management"
set "L_SEC_POWER=Restart or shut down the system"
set "L_M_DISKPART=Start Diskpart (partition management)"
set "L_M_QUIT=Quit"
set "L_ASK_DEFRAG=Which drive do you want to defragment? (e.g. C: / 0=Back):"
set "L_ASK_CHK=Which drive do you want to check/repair? (e.g. C: / 0=Back):"
set "L_ASK_TRIM=Which drive do you want to trim? (e.g. C: / 0=Back):"
set "L_SYSDEV1=System drive detected."
set "L_SYSDEV2=CHKDSK /f will be scheduled for the next reboot,"
set "L_SYSDEV3=if the drive cannot be locked."
set "L_CONFIRM1=If Windows asks whether the check should be run"
set "L_CONFIRM2=at the next reboot, confirm with Y."
set "L_DP1=Note: Diskpart works directly on the disks -"
set "L_DP2=Check commands carefully (list disk, sel disk, ...)."
set "L_DP3=Type "exit" to leave Diskpart and return to the menu."
set "L_PM1=Restart"
set "L_PM2=Shut down"
set "L_P0=Back"
set "L_WARN_R=WARNING: The system will now restart."
set "L_WARN_S=WARNING: The system will now shut down."
set "L_ST_OK=Command completed successfully."
set "L_ST_FAIL=Command terminated with exit code"
set "L_NODRIVE=No drive specified."
set "L_EXAMPLE=Example: hdd -d C:"
set "L_NF_PRE=Drive"
set "L_NF_SUF=not found."
set "L_UNKNOWN=Unknown argument:"
set "L_U_D=Defragment a hard drive"
set "L_U_C=Check and repair for errors (chkdsk /f)"
set "L_U_T=Perform SSD trim"
set "L_U_R=Restart the system"
set "L_U_S=Shut down the system"
set "L_U_NC=Disable colors (combinable, e.g. hdd -nc -d C:)"
set "L_U_DE=Force German (combinable, e.g. hdd -de -d C:)"
set "L_U_EN=Force English (combinable, e.g. hdd -en -d C:)"
set "L_U_H=Show this help"
set "L_U_NOARG=Without arguments the interactive mode starts."
exit /b
