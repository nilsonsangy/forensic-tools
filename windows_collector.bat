:: Author: Nilson Sangy
:: https://github.com/nilsonsangy/tools

@echo off

echo Extraction script of relevant volatile informations.
echo Run with admin privileges.
set /p resultFolder="Insert the root folder to save the result. It will be created a folder inside:"
rd /s /q "%resultFolder%\%computername%_result"
mkdir "%resultFolder%\%computername%_result"
set COMPUTERNAMERESULT="%resultFolder%\%computername%_result"

:: Insert the Sysinternals path here
set sysintfolder="C:\Users\nilso\Desktop\tools\Sysinternals\"

echo Coletando Data e Hora
date /t > %COMPUTERNAMERESULT%\data_hora.txt
time /t >> %COMPUTERNAMERESULT%\data_hora.txt
systeminfo | find Fuso >> %COMPUTERNAMERESULT%\data_hora.txt
systeminfo | find Time Zone >> %COMPUTERNAMERESULT%\data_hora.txt

echo Coletando Numero Serial do Computador
wmic bios get serialnumber > %COMPUTERNAMERESULT%\numero_serial.txt

echo Coletando SID do Computador
%sysintfolder%psgetsid -nobanner -accepteula >> %COMPUTERNAMERESULT%\SID.txt

echo Coletando Informacoes do Computador
systeminfo > %COMPUTERNAMERESULT%\info_computador.txt
echo: >> %COMPUTERNAMERESULT%\info_computador.txt
echo: >> %COMPUTERNAMERESULT%\info_computador.txt
%sysintfolder%psinfo -d -s -h -nobanner -accepteula >> %COMPUTERNAMERESULT%\info_computador.txt

echo Obtendo Informacoes das Interfaces de Rede
ipconfig /all > %COMPUTERNAMERESULT%\ip_mac_interfaces.txt

echo Coletando Historico
doskey /history > %COMPUTERNAMERESULT%\historico.txt

echo Coletando Usuarios Autenticados
%sysintfolder%psloggedon -nobanner -accepteula > %COMPUTERNAMERESULT%\usuarios_autenticados.txt

echo Coletando Conexoes, Portas e Processos
netstat -nabo > %COMPUTERNAMERESULT%\conexoes_portas_processos.txt

echo Coletando Tabela de Rotas
netstat -rn > %COMPUTERNAMERESULT%\rotas.txt

echo Coletando Compartilhamentos
net use > %COMPUTERNAMERESULT%\compartilhamentos.txt

echo Coletando Arquivos Compartilhados Abertos em um Servidor
net file > %COMPUTERNAMERESULT%\arquivos_abertos.txt

echo Coletando Sessoes Abertas com outros sistemas
net sessions > %COMPUTERNAMERESULT%\sessoes_abertas.txt

echo Coletando Lista de Processos
%sysintfolder%pslist -nobanner -accepteula > %COMPUTERNAMERESULT%\processos.txt

echo Coletando Processos e seus Modulos
tasklist /M > %COMPUTERNAMERESULT%\processos_modulos.txt

echo Coletando Processos da Sessao de Logon
%sysintfolder%logonsessions -p -nobanner -accepteula > %COMPUTERNAMERESULT%\processos_sessaodelogon.txt

echo Gerando Hashes
cd %COMPUTERNAMERESULT%\
fsum -sha256 *.txt > ..\hashes.txt
move ..\hashes.txt .