@echo off
rem Oyunu yerel sunucuda acar. (Tarayici, modulleri dosyadan dogrudan yuklemez; kucuk bir sunucu gerekir.)
cd /d "%~dp0"
start "" http://localhost:8123/
python -m http.server 8123
