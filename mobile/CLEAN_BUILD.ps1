# COMPLETE BUILD CLEANUP SCRIPT
# Run this in PowerShell if you get ANY gradle errors

Write-Host "KILLING ALL PROCESSES..."
Get-Process | Where-Object {$_.ProcessName -match "flutter|dart|gradle|java|javaw|adb"} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 5

Write-Host "DELETING ALL GRADLE CACHES..."
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.android" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Google\AndroidStudio*" -ErrorAction SilentlyContinue

Write-Host "DELETING PROJECT BUILD FILES..."
Remove-Item -Recurse -Force ".\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.gradle" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\.dart_tool" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\android\build" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force ".\android\.gradle" -ErrorAction SilentlyContinue

Write-Host "DONE. Now run: flutter clean && flutter pub get && flutter run"
