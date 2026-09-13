@echo off
title QRFlux PC Host Server
echo ===================================================
echo   QRFlux — High-Speed Direct Offline Wi-Fi Sharing
echo ===================================================
echo Starting PC Transfer Engine & Web Host...
echo.
dart run bin/server.dart
pause
