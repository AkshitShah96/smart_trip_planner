@echo off
echo Installing dependencies...
flutter pub get
echo.
echo Generating Isar schema files...
dart run build_runner build --delete-conflicting-outputs
echo.
echo Build complete!
pause













