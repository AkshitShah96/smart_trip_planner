@echo off
setlocal ENABLEDELAYEDEXPANSION
echo ========================================
echo Google Maps API Key Setup
echo ========================================
echo.
echo This will write your API key into android\local.properties and print Web setup.
echo.
set /p MAPS_API_KEY=Paste your Google Maps API key: 
if "%MAPS_API_KEY%"=="" (
  echo No key entered. Exiting.
  exit /b 1
)

set "LP=android\local.properties"
if exist "%LP%.bak" del "%LP%.bak"
copy /y "%LP%" "%LP%.bak" >nul
for /f "usebackq delims=" %%L in ("%LP%") do (
  echo %%L>> "%LP%.tmp"
)
findstr /b /c:"MAPS_API_KEY=" "%LP%" >nul
if %errorlevel%==0 (
  powershell -NoProfile -Command "(Get-Content '%LP%' -Raw) -replace 'MAPS_API_KEY=.*','MAPS_API_KEY=%MAPS_API_KEY%' | Set-Content '%LP%' -Encoding UTF8"
) else (
  echo MAPS_API_KEY=%MAPS_API_KEY%>> "%LP%"
)
if exist "%LP%.tmp" del "%LP%.tmp"
echo.
echo Android configured. For Web, set env before run:
echo   set MAPS_API_KEY=%MAPS_API_KEY%
echo Then run:
echo   flutter run -d chrome
echo.
echo Done.
endlocal