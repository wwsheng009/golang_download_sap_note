

@REM extra all sar files
for %%F in (*.SAR) do (
    "SAPCAR.exe" -xvVf "%%F"
)

@REM extra all zip files
for %%F in (*.zip) do (
    "C:\Program Files\7-Zip\7z.exe" x "%%F" -o"%%~nF"
)