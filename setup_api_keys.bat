@echo off
echo ========================================
echo Smart Trip Planner - API Key Setup
echo ========================================
echo.

echo This script will help you set up API keys for real LLM integration.
echo.

echo Choose your API provider:
echo 1. OpenAI (GPT-4)
echo 2. Google Gemini Pro
echo 3. Both OpenAI and Gemini
echo 4. Skip (use demo mode)
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto openai_setup
if "%choice%"=="2" goto gemini_setup
if "%choice%"=="3" goto both_setup
if "%choice%"=="4" goto demo_mode
goto invalid_choice

:openai_setup
echo.
echo Setting up OpenAI API key...
set /p openai_key="Enter your OpenAI API key (starts with sk-): "
if "%openai_key%"=="" (
    echo Error: API key cannot be empty!
    goto end
)
setx OPENAI_API_KEY "%openai_key%"
echo.
echo ✅ OpenAI API key set successfully!
echo.
echo To run the app with OpenAI:
echo flutter run -d chrome
goto end

:gemini_setup
echo.
echo Setting up Google Gemini API key...
set /p gemini_key="Enter your Gemini API key: "
if "%gemini_key%"=="" (
    echo Error: API key cannot be empty!
    goto end
)
setx GEMINI_API_KEY "%gemini_key%"
echo.
echo ✅ Google Gemini API key set successfully!
echo.
echo To run the app with Gemini:
echo flutter run -d chrome
goto end

:both_setup
echo.
echo Setting up both API keys...
set /p openai_key="Enter your OpenAI API key (starts with sk-): "
set /p gemini_key="Enter your Gemini API key: "
if "%openai_key%"=="" (
    echo Error: OpenAI API key cannot be empty!
    goto end
)
if "%gemini_key%"=="" (
    echo Error: Gemini API key cannot be empty!
    goto end
)
setx OPENAI_API_KEY "%openai_key%"
setx GEMINI_API_KEY "%gemini_key%"
echo.
echo ✅ Both API keys set successfully!
echo.
echo To run the app with both APIs:
echo flutter run -d chrome
goto end

:demo_mode
echo.
echo ✅ Demo mode selected. The app will use mock data.
echo.
echo To run the app in demo mode:
echo flutter run -d chrome
goto end

:invalid_choice
echo.
echo ❌ Invalid choice. Please run the script again.
goto end

:end
echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Close and reopen your terminal/IDE
echo 2. Run: flutter run -d chrome
echo 3. Check the status in the app to verify API integration
echo.
echo For more information, see LLM_INTEGRATION_GUIDE.md
echo.
pause

