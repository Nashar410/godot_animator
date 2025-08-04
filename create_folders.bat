@echo off
echo Creating Godot Pixel Art Series folder structure...

REM Structure src/
mkdir src
mkdir src\core
mkdir src\core\factories
mkdir src\core\managers
mkdir src\core\validators
mkdir src\core\exporters
mkdir src\components
mkdir src\components\characters
mkdir src\components\dialogue
mkdir src\components\effects
mkdir src\components\transitions

REM Structure assets/
mkdir assets
mkdir assets\characters
mkdir assets\tilesets
mkdir assets\effects
mkdir assets\audio
mkdir assets\audio\music
mkdir assets\audio\sfx
mkdir assets\audio\voices
mkdir assets\audio\ambience
mkdir assets\ui

REM Structure episodes/
mkdir episodes

REM Structure export/
mkdir export

echo.
echo Folder structure created successfully!
echo.
echo Structure created:
echo - src/ (code source)
echo - assets/ (ressources)
echo - episodes/ (fichiers JSON)
echo - export/ (videos exportees)
echo.
pause