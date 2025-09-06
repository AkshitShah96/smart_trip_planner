@echo off
echo ========================================
echo Google Maps API Key Setup
echo ========================================
echo.
echo To use Google Maps in your Flutter app, you need to:
echo.
echo 1. Go to Google Cloud Console: https://console.cloud.google.com/
echo 2. Create a new project or select existing one
echo 3. Enable the following APIs:
echo    - Maps JavaScript API
echo    - Maps Static API
echo    - Geocoding API
echo    - Places API
echo 4. Create credentials (API Key)
echo 5. Restrict the API key to your domain (for production)
echo.
echo 6. Set the API key as an environment variable:
echo    set GOOGLE_MAPS_API_KEY=your_api_key_here
echo.
echo 7. Or add it to your .env file:
echo    GOOGLE_MAPS_API_KEY=your_api_key_here
echo.
echo 8. Restart your Flutter app
echo.
echo ========================================
echo Current API Key Status:
echo ========================================
if defined GOOGLE_MAPS_API_KEY (
    echo API Key is configured: %GOOGLE_MAPS_API_KEY%
) else (
    echo API Key is NOT configured
    echo Please set GOOGLE_MAPS_API_KEY environment variable
)
echo.
echo ========================================
echo For more help, visit:
echo https://developers.google.com/maps/documentation/javascript/get-api-key
echo ========================================
pause

