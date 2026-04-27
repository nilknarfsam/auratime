@echo off
set /p msg="Digite a mensagem do commit: "
if "%msg%"=="" set msg="Update AuraTime"

echo.
echo [1/3] Adicionando arquivos...
git add .

echo [2/3] Criando commit: %msg%
git commit -m "%msg%"

echo [3/3] Enviando para o GitHub (Main)...
git push origin main

echo.
echo Pronto! Codigo enviado com sucesso.
pause