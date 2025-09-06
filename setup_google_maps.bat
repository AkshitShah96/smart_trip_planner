@echo off
echo ========================================
echo Smart Trip Planner - Google Maps Setup
echo ========================================
echo.

echo This script will help you set up Google Maps API integration.
echo.

echo Step 1: Get your Google Maps API Key
echo ------------------------------------
echo 1. Go to Google Cloud Console: https://console.cloud.google.com/
echo 2. Create a new project or select an existing one
echo 3. Enable the following APIs:
echo    - Maps SDK for Android
echo    - Maps SDK for iOS  
echo    - Maps JavaScript API
echo    - Static Maps API
echo    - Embed Maps API
echo 4. Go to "APIs & Services" ^> "Credentials"
echo 5. Click "Create Credentials" ^> "API Key"
echo 6. Copy your API key
echo.

set /p API_KEY="Enter your Google Maps API Key: "

if "%API_KEY%"=="" (
    echo Error: API key cannot be empty!
    pause
    exit /b 1
)

echo.
echo Step 2: Configure API Key for Flutter
echo -------------------------------------

echo Creating environment configuration...

REM Create .env file for API key
echo GOOGLE_MAPS_API_KEY=%API_KEY% > .env

REM Update Android configuration
echo Updating Android configuration...
(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android"^>
echo     ^<application^>
echo         ^<meta-data
echo             android:name="com.google.android.geo.API_KEY"
echo             android:value="%API_KEY%" /^>
echo     ^</application^>
echo ^</manifest^>
) > android\app\src\main\AndroidManifest.xml.template

echo Android configuration template created at: android\app\src\main\AndroidManifest.xml.template
echo Please copy the meta-data section to your actual AndroidManifest.xml file.

REM Update iOS configuration
echo.
echo Updating iOS configuration...
echo Please add the following to your ios\Runner\AppDelegate.swift file:
echo.
echo import GoogleMaps
echo GMSServices.provideAPIKey^("%API_KEY%"^)
echo.

REM Create run script with API key
echo Creating run script with API key...
echo @echo off > run_with_maps.bat
echo flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=%API_KEY% >> run_with_maps.bat

echo.
echo Step 3: Test Configuration
echo --------------------------
echo Your Google Maps API key has been configured!
echo.
echo To test the configuration:
echo 1. Run: run_with_maps.bat
echo 2. Or manually: flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=%API_KEY%
echo.

echo Step 4: API Key Security
echo ------------------------
echo IMPORTANT: Keep your API key secure!
echo - Never commit your API key to version control
echo - Restrict your API key to specific domains/IPs
echo - Monitor your API usage in Google Cloud Console
echo - Set up billing alerts to avoid unexpected charges
echo.

echo Setup complete! Your Smart Trip Planner now has Google Maps integration.
echo.
pause
