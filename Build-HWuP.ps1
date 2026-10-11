# Build-HWuP.ps1 - compila HWuP.ps1 em HWuP.exe usando PS2EXE.
# Rode isto no Windows, na MESMA pasta onde estao HWuP.ps1 e hwup.ico.

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $here "HWuP.ps1"
$ico  = Join-Path $here "hwup.ico"
$out  = Join-Path $here "HWuP.exe"

Write-Host "=== HWuP Build ===" -ForegroundColor Yellow

if (-not (Test-Path $src)) {
    Write-Host "ERRO: HWuP.ps1 nao encontrado em $here" -ForegroundColor Red
    Write-Host "Coloque este arquivo na MESMA pasta do HWuP.ps1 e tente de novo."
    Read-Host "Pressione ENTER para sair"
    exit 1
}

Write-Host "PowerShell detectado: $($PSVersionTable.PSVersion)"

$mod = Get-Module -ListAvailable -Name ps2exe
if (-not $mod) {
    Write-Host "O modulo 'ps2exe' nao esta instalado nesta conta de usuario." -ForegroundColor Yellow
    $r = Read-Host "Instalar agora (Install-Module ps2exe -Scope CurrentUser)? (S/N)"
    if ($r -match '^[sS]') {
        try {
            Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
        } catch {
            Write-Host "Falha ao instalar o modulo ps2exe:" -ForegroundColor Red
            Write-Host "$_" -ForegroundColor Red
            Read-Host "Pressione ENTER para sair"
            exit 1
        }
    } else {
        Write-Host "Instalacao cancelada pelo usuario. Nao e possivel compilar sem o ps2exe."
        Read-Host "Pressione ENTER para sair"
        exit 1
    }
}
Import-Module ps2exe -Force

$params = @{
    inputFile    = $src
    outputFile   = $out
    noConsole    = $true
    requireAdmin = $true
    title        = "HWuP"
    product      = "HWuP Windows Environment Manager"
    version      = "1.0.0.0"
}
if (Test-Path $ico) {
    $params["iconFile"] = $ico
} else {
    Write-Host "Aviso: hwup.ico nao encontrado nesta pasta - compilando com icone padrao." -ForegroundColor Yellow
}

Write-Host "Compilando HWuP.exe ..." -ForegroundColor Yellow
try {
    Invoke-ps2exe @params
} catch {
    Write-Host "ERRO na compilacao:" -ForegroundColor Red
    Write-Host "$_" -ForegroundColor Red
    Read-Host "Pressione ENTER para sair"
    exit 1
}

if (Test-Path $out) {
    Write-Host ""
    Write-Host "OK - Executavel gerado com sucesso:" -ForegroundColor Green
    Write-Host $out -ForegroundColor Green
} else {
    Write-Host "ERRO: a compilacao terminou mas $out nao foi encontrado." -ForegroundColor Red
}
Read-Host "Pressione ENTER para sair"
