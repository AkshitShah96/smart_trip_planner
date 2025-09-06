@echo off
echo Adding all project files to GitHub...
git add lib/
git add android/
git add ios/
git add web/
git add test/
git add pubspec.yaml
git add pubspec.lock
git add analysis_options.yaml
git add build.yaml
git add README.md
git add .gitignore
git commit -m "Add all project files and folders"
git push origin main
echo Done! All files added to GitHub.
pause





