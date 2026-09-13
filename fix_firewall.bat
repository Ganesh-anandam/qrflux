@echo off
echo Configuring Windows Firewall and Network Profile for QRFlux...
netsh advfirewall firewall delete rule name="QRFlux File Transfer" >nul 2>&1
netsh advfirewall firewall add rule name="QRFlux File Transfer" dir=in action=allow protocol=TCP localport=2121,8080 profile=any
powershell -Command "Set-NetConnectionProfile -InterfaceAlias Wi-Fi -NetworkCategory Private" >nul 2>&1
echo Done! Ports 2121 and 8080 are now allowed.
