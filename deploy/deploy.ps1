# Publica a versão web do Mamata em https://mamata.fun
# Uso (PowerShell, na pasta do projeto):  .\deploy\deploy.ps1 -Server root@IP_DA_VPS
param(
    [Parameter(Mandatory = $true)][string]$Server,
    [string]$RemoteDir = '/var/www/mamata.fun',
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $SkipBuild) {
    flutter build web --release
    if ($LASTEXITCODE -ne 0) { throw 'Falha no build web.' }
}

# Envia para uma pasta temporária e troca de uma vez (o site não fica "meio atualizado").
$tmp = "$RemoteDir.new"
ssh $Server "rm -rf $tmp && mkdir -p $tmp"
scp -r build/web/* "${Server}:$tmp/"
if ($LASTEXITCODE -ne 0) { throw 'Falha no envio dos arquivos.' }
ssh $Server "rm -rf $RemoteDir.old; if [ -d $RemoteDir ]; then mv $RemoteDir $RemoteDir.old; fi; mv $tmp $RemoteDir && rm -rf $RemoteDir.old"
Write-Host 'Publicado em https://mamata.fun' -ForegroundColor Green
