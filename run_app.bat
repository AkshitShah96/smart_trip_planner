@echo off
echo Starting Smart Trip Planner App...
echo.
echo Getting dependencies...
flutter pub get
echo.
echo Running app in web browser...
flutter run -d chrome --web-port 8080
echo.
echo App should open in your browser at http://localhost:8080
pause













