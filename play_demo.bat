@echo off
rem Demo-Sprint: Mega Tycoon Demo starten (Windows). Doppelklick genuegt, wenn Godot 4.7.2 gefunden wird.
rem Reihenfolge: Variable GODOT, Godot*.exe in diesem Ordner, im Ordner darueber (z. B. C:\Dev), dann "godot" im PATH.
setlocal
set "HIER=%~dp0"
set "G=%GODOT%"
if not defined G for %%F in ("%HIER%Godot*.exe") do if not defined G set "G=%%~fF"
if not defined G for %%F in ("%HIER%..\Godot*.exe") do if not defined G set "G=%%~fF"
if not defined G for /f "delims=" %%F in ('where godot 2^>nul') do if not defined G set "G=%%F"
if not defined G (
  echo Godot wurde nicht gefunden.
  echo Lege die Godot-4.7.2-Datei ^(Godot_v4.7.2-stable_win64.exe^) in diesen Ordner oder nach C:\Dev,
  echo oder ziehe sie auf diese Datei ^(play_demo.bat^).
  if not "%~1"=="" set "G=%~1"
)
if not defined G (
  pause
  exit /b 2
)
if not exist "%HIER%slice\.godot" (
  echo Erster Start: Godot importiert das Projekt, das dauert ein bis zwei Minuten ...
  "%G%" --headless --path "%HIER%slice" --import
)
"%G%" --path "%HIER%slice" -- --demo
endlocal
