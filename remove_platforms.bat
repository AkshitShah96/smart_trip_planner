@echo off
echo Removing iOS, Linux, and macOS folders...
rmdir /s /q ios
rmdir /s /q linux
rmdir /s /q macos
git add -A
git commit -m "Remove iOS, Linux, and macOS platform folders"
git push origin main
echo Done! Platform folders removed from GitHub.
pause

