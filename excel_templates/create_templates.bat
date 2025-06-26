@echo off
echo Creating Excel Templates for Model Registry...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Install required packages
echo Installing required packages...
pip install pandas openpyxl

REM Create templates
echo.
echo Creating Excel templates...
python create_templates.py

echo.
echo Template creation completed!
echo Check the 'templates' and 'sample_data' folders for the generated files.
pause 