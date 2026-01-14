@echo off
for /r lib %%f in (*.dart) do (
    powershell -Command "(Get-Content '%%f') -replace 'package:my_app', 'package:smartstay' | Set-Content '%%f'"
)
echo All imports updated!
