# =====================================================================
# HWuP - Windows Environment Manager / Gerenciador de Ambientes Windows
# Version 1.0.0 (Fase 1)  -  Windows PowerShell 5.1
# ASCII-only source to avoid encoding problems.
#
# Fase 1 entrega: diagnostico real (DSE inferido, Secure Boot com aviso
# de firmware, reboot pendente, firewall por perfil), Enter Test Mode e
# Restore Protected Mode com plano de mudancas + confirmacao + log real
# + verificacao, lembretes/retorno automatico via Agendador de Tarefas,
# contagem regressiva cancelavel, relatorio TXT/JSON, About com link,
# interface bilingue PT/EN nos textos principais.
#
# Fora da Fase 1 (declarado, nao fingido): gerenciamento de rede
# (desativar/reativar adaptadores) fica para a Fase 2.
# =====================================================================

param(
    [switch]$AutoRestore   # usado pela tarefa agendada de retorno automatico
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------------
# Paths / state
# ---------------------------------------------------------------------
$script:AppDir   = Join-Path $env:LOCALAPPDATA "HWuP"
$script:LogDir   = Join-Path $script:AppDir "logs"
$script:StateFile = Join-Path $script:AppDir "hwup-state.json"
foreach ($p in @($script:AppDir, $script:LogDir)) {
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
$script:LogFile = Join-Path $script:LogDir ("hwup-" + (Get-Date -Format "yyyyMMdd") + ".log")
$script:ScriptSelf = $PSCommandPath
if (-not $script:ScriptSelf) { $script:ScriptSelf = $MyInvocation.MyCommand.Path }

function Get-HWuPState {
    if (Test-Path $script:StateFile) {
        try { return (Get-Content $script:StateFile -Raw | ConvertFrom-Json) } catch {}
    }
    return [pscustomobject]@{
        HypervisorLaunchTypeChangedByHWuP = $false
        LastProfileApplied = "UNKNOWN"
        LastAppliedAt = $null
        DisabledAdaptersByHWuP = @()
    }
}
function Save-HWuPState($StateObj) {
    try { $StateObj | ConvertTo-Json | Set-Content -Path $script:StateFile -Encoding UTF8 } catch {}
}

# ---------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------
$script:Lang = "PT"
$S = @{
"PT" = @{
    AppTitle = "HWuP - WINDOWS ENVIRONMENT MANAGER"
    AppSub   = "Gerenciador de Ambientes do Windows"
    EnvLabel = "ESTADO ATUAL"
    EnvProtected = "AMBIENTE PROTEGIDO"
    EnvTest      = "AMBIENTE DE TESTE"
    EnvMixed     = "AMBIENTE MISTO / PARCIALMENTE CONFIGURADO"
    EnvUnknown   = "ESTADO NAO CLASSIFICADO"
    DiagTitle = "DIAGNOSTICO DO WINDOWS"
    ColName = "Item"; ColState = "Estado"; ColSource = "Fonte"; ColNote = "Observacao"
    BtnRefresh = "ATUALIZAR"
    BtnEnterTest = "ENTRAR EM MODO DE TESTE"
    BtnRestore = "RESTAURAR AMBIENTE PROTEGIDO"
    BtnReport = "SALVAR RELATORIO"
    BtnReminders = "LEMBRETES"
    BtnNetwork = "REDE (EM BREVE)"
    BtnAbout = "SOBRE"
    BtnExit = "SAIR"
    BtnLang = "ENGLISH"
    ProgressIdle = "OCIOSO"
    LogTitle = "LOG DE ATIVIDADE"
    StateON = "ATIVO"; StateOFF = "INATIVO"; StateUNK = "DESCONHECIDO"
    StateNA = "NAO APLICAVEL (BIOS/UEFI)"; StateMANUAL = "ACAO MANUAL"
    StatePENDING = "CONFIGURADO - PENDENTE REINICIAR"
    PlanTitleTest = "HWuP - ENTRAR EM MODO DE TESTE"
    PlanTitleRestore = "HWuP - RESTAURAR AMBIENTE PROTEGIDO"
    PlanIntroTest = "As seguintes alteracoes serao aplicadas para permitir carregar drivers nao assinados. Isso REDUZ a seguranca do Windows. Nao use o Modo de Teste para navegacao, downloads desconhecidos ou jogos online."
    PlanIntroRestore = "As seguintes alteracoes serao aplicadas para retornar ao perfil protegido recomendado para uso diario."
    PlanNoChanges = "Nada a fazer: o sistema ja esta de acordo com este perfil."
    PlanUnchanged = "Sem alteracao"
    PlanAuto = "Automatico"
    PlanManual = "Manual (BIOS/UEFI)"
    PlanRebootYes = "Requer reinicializacao"
    PlanRebootNo = "Nao requer reinicializacao"
    PlanOptHyperv = "Tambem desligar o hipervisor (hypervisorlaunchtype off)"
    PlanOptHypervWarn = "ATENCAO: isso impede o funcionamento de Hyper-V, WSL2 e Sandbox ate ser revertido."
    PlanSecureBootWarn = "Secure Boot esta ATIVO. Em muitas configuracoes, o Windows ignora testsigning com Secure Boot ligado. Desative o Secure Boot na BIOS/UEFI se precisar carregar drivers de teste de forma confiavel."
    BtnCancel = "CANCELAR"
    BtnConfirmTest = "CONFIRMAR E REINICIAR"
    BtnConfirmRestore = "CONFIRMAR E REINICIAR"
    CountdownTitle = "HWuP - REINICIANDO"
    CountdownMsg = "O computador sera reiniciado em"
    CountdownCancel = "CANCELAR REINICIALIZACAO"
    CountdownCanceled = "Reinicializacao cancelada pelo usuario. Algumas alteracoes so terao efeito apos reiniciar manualmente."
    ReminderTitle = "HWuP - LEMBRETE"
    ReminderIntro = "Voce esta no Ambiente de Teste. Deseja ser lembrado de voltar ao ambiente protegido?"
    Rem1h = "Lembrar em 1 hora"; Rem2h = "Lembrar em 2 horas"; Rem3h = "Lembrar em 3 horas"
    RemAuto = "Retornar automaticamente em 1 hora"
    RemNone = "Nao lembrar agora"
    RemNote = "Um lembrete apenas avisa; a restauracao automatica cria uma tarefa agendada que executa o Restore sozinha."
    BtnConfirmSmall = "CONFIRMAR"
    RemindersListTitle = "HWuP - TAREFAS AGENDADAS"
    RemindersNone = "Nenhuma tarefa agendada do HWuP no momento."
    BtnRemoveTask = "REMOVER"
    BtnClose = "FECHAR"
    AboutTitle = "SOBRE O HWuP"
    AboutBody = "HWuP - Windows Environment Manager`r`nVersao 1.0.0 (Fase 1)`r`n`r`nDiagnostica o ambiente de seguranca do Windows e alterna, de forma controlada e verificavel, entre o perfil protegido de uso diario e um perfil de testes para desenvolvimento/depuracao de drivers.`r`n`r`nO Modo de Teste reduz deliberadamente certas protecoes (assinatura de drivers, integridade de memoria) e nao deve ser usado para uso cotidiano. O HWuP nunca desativa Defender, Firewall ou Secure Boot.`r`n`r`nCanal oficial:"
    AboutLink = "https://www.youtube.com/HwupTech"
    ReportSaved = "Relatorio salvo em:"
    ReportError = "Erro ao salvar relatorio"
    ExitBusyTitle = "Operacao em andamento"
    ExitBusyMsg = "Uma operacao ainda esta em andamento. Fechar agora pode deixar o sistema em um estado intermediario. Fechar mesmo assim?"
    NetSummary = "adaptador(es) ativo(s)"
    NetDlgTitle = "HWuP - REDE DURANTE O TESTE"
    NetDlgIntro = "Deseja manter a rede ativa ou desativar adaptadores especificos durante o Modo de Teste? A desconexao reduz exposicao a rede, mas nao substitui as demais protecoes. Voce pode reativar a qualquer momento pelo botao REDE."
    NetDlgNone = "Nenhum adaptador ativo foi encontrado."
    NetDlgKeep = "(manter ativo)"
    BtnReactivateNetwork = "REATIVAR REDE"
    ReactivateTitle = "HWuP - REATIVAR REDE"
    ReactivateIntro = "Os seguintes adaptadores foram desativados pelo HWuP e serao reativados:"
    ReactivateNone = "Nenhum adaptador foi desativado pelo HWuP."
    BtnConfirmReactivate = "REATIVAR AGORA"
}
"EN" = @{
    AppTitle = "HWuP - WINDOWS ENVIRONMENT MANAGER"
    AppSub   = "Windows Environment Manager"
    EnvLabel = "CURRENT ENVIRONMENT"
    EnvProtected = "PROTECTED ENVIRONMENT"
    EnvTest      = "TEST ENVIRONMENT"
    EnvMixed     = "MIXED / PARTIALLY CONFIGURED"
    EnvUnknown   = "STATE NOT CLASSIFIED"
    DiagTitle = "WINDOWS DIAGNOSTICS"
    ColName = "Item"; ColState = "State"; ColSource = "Source"; ColNote = "Note"
    BtnRefresh = "REFRESH"
    BtnEnterTest = "ENTER TEST MODE"
    BtnRestore = "RESTORE PROTECTED MODE"
    BtnReport = "SAVE REPORT"
    BtnReminders = "REMINDERS"
    BtnNetwork = "NETWORK (COMING SOON)"
    BtnAbout = "ABOUT"
    BtnExit = "EXIT"
    BtnLang = "PORTUGUES"
    ProgressIdle = "IDLE"
    LogTitle = "ACTIVITY LOG"
    StateON = "ACTIVE"; StateOFF = "INACTIVE"; StateUNK = "UNKNOWN"
    StateNA = "NOT APPLICABLE (BIOS/UEFI)"; StateMANUAL = "MANUAL ACTION"
    StatePENDING = "CONFIGURED - PENDING REBOOT"
    PlanTitleTest = "HWuP - ENTER TEST MODE"
    PlanTitleRestore = "HWuP - RESTORE PROTECTED MODE"
    PlanIntroTest = "The following changes will be applied to allow loading unsigned drivers. This REDUCES Windows security. Do not use Test Mode for browsing, unknown downloads, or online games."
    PlanIntroRestore = "The following changes will be applied to return to the recommended protected profile for daily use."
    PlanNoChanges = "Nothing to do: the system already matches this profile."
    PlanUnchanged = "No change"
    PlanAuto = "Automatic"
    PlanManual = "Manual (BIOS/UEFI)"
    PlanRebootYes = "Requires restart"
    PlanRebootNo = "No restart required"
    PlanOptHyperv = "Also turn off the hypervisor (hypervisorlaunchtype off)"
    PlanOptHypervWarn = "WARNING: this breaks Hyper-V, WSL2 and Sandbox until reverted."
    PlanSecureBootWarn = "Secure Boot is ON. On many configurations Windows ignores testsigning while Secure Boot is on. Disable Secure Boot in BIOS/UEFI if you need test drivers to load reliably."
    BtnCancel = "CANCEL"
    BtnConfirmTest = "CONFIRM AND RESTART"
    BtnConfirmRestore = "CONFIRM AND RESTART"
    CountdownTitle = "HWuP - RESTARTING"
    CountdownMsg = "The computer will restart in"
    CountdownCancel = "CANCEL RESTART"
    CountdownCanceled = "Restart canceled by user. Some changes will only take effect after a manual restart."
    ReminderTitle = "HWuP - REMINDER"
    ReminderIntro = "You are in Test Mode. Would you like to be reminded to return to the protected environment?"
    Rem1h = "Remind me in 1 hour"; Rem2h = "Remind me in 2 hours"; Rem3h = "Remind me in 3 hours"
    RemAuto = "Automatically return in 1 hour"
    RemNone = "Do not remind me now"
    RemNote = "A reminder only notifies you; auto-restore creates a scheduled task that runs Restore by itself."
    BtnConfirmSmall = "CONFIRM"
    RemindersListTitle = "HWuP - SCHEDULED TASKS"
    RemindersNone = "No HWuP scheduled tasks at the moment."
    BtnRemoveTask = "REMOVE"
    BtnClose = "CLOSE"
    AboutTitle = "ABOUT HWuP"
    AboutBody = "HWuP - Windows Environment Manager`r`nVersion 1.0.0 (Phase 1)`r`n`r`nDiagnoses the Windows security environment and switches, in a controlled and verifiable way, between the daily-use protected profile and a test profile for driver development/debugging.`r`n`r`nTest Mode deliberately reduces certain protections (driver signing, memory integrity) and should not be used for everyday use. HWuP never disables Defender, Firewall or Secure Boot.`r`n`r`nOfficial channel:"
    AboutLink = "https://www.youtube.com/HwupTech"
    ReportSaved = "Report saved to:"
    ReportError = "Error saving report"
    ExitBusyTitle = "Operation in progress"
    ExitBusyMsg = "An operation is still running. Closing now may leave the system in an intermediate state. Close anyway?"
    NetSummary = "active adapter(s)"
    NetDlgTitle = "HWuP - NETWORK DURING TEST"
    NetDlgIntro = "Keep the network active, or disable specific adapters during Test Mode? Disconnecting reduces network exposure but does not replace the other protections. You can reactivate anytime via the NETWORK button."
    NetDlgNone = "No active adapters were found."
    NetDlgKeep = "(keep active)"
    BtnReactivateNetwork = "REACTIVATE NETWORK"
    ReactivateTitle = "HWuP - REACTIVATE NETWORK"
    ReactivateIntro = "The following adapters were disabled by HWuP and will be reactivated:"
    ReactivateNone = "No adapter was disabled by HWuP."
    BtnConfirmReactivate = "REACTIVATE NOW"
}
}
function Tx([string]$Key) {
    if ($S[$script:Lang].ContainsKey($Key)) { return $S[$script:Lang][$Key] }
    return $Key
}

# ---------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------
$BG=[System.Drawing.Color]::FromArgb(10,10,10); $PANEL=[System.Drawing.Color]::FromArgb(22,22,22)
$PANEL2=[System.Drawing.Color]::FromArgb(32,32,32); $ORANGE=[System.Drawing.Color]::FromArgb(255,140,0)
$GREEN=[System.Drawing.Color]::FromArgb(60,210,110); $RED=[System.Drawing.Color]::FromArgb(235,70,70)
$YELLOW=[System.Drawing.Color]::FromArgb(245,190,50); $WHITE=[System.Drawing.Color]::FromArgb(235,235,235)
$GRAY=[System.Drawing.Color]::FromArgb(155,155,155)

# ---------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------
function New-Label { param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H,[int]$Size=10,[System.Drawing.Color]$Color=$WHITE)
    $c = New-Object System.Windows.Forms.Label
    $c.Text=$Text; $c.Location=New-Object System.Drawing.Point($X,$Y); $c.Size=New-Object System.Drawing.Size($W,$H)
    $c.Font=New-Object System.Drawing.Font("Segoe UI",$Size); $c.ForeColor=$Color
    $c.BackColor=[System.Drawing.Color]::Transparent; $c.AutoSize=$false
    return $c
}
function New-Button { param([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H)
    $c = New-Object System.Windows.Forms.Button
    $c.Text=$Text; $c.Location=New-Object System.Drawing.Point($X,$Y); $c.Size=New-Object System.Drawing.Size($W,$H)
    $c.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $c.ForeColor=$WHITE; $c.BackColor=$PANEL2; $c.FlatStyle=[System.Windows.Forms.FlatStyle]::Flat
    $c.FlatAppearance.BorderColor=$ORANGE; $c.FlatAppearance.BorderSize=1
    $c.Cursor=[System.Windows.Forms.Cursors]::Hand
    return $c
}

# ---------------------------------------------------------------------
# Logging: GUI + persistent file + in-memory structured log for reports
# ---------------------------------------------------------------------
$script:LogEntries = New-Object System.Collections.Generic.List[object]
function Write-Log([string]$Message,[string]$Level="INFO") {
    $ts = Get-Date -Format "HH:mm:ss"
    $tag = switch ($Level) { "OK"{"[OK]"} "FAIL"{"[FAIL]"} "WARN"{"[WARN]"} "SKIP"{"[SKIP]"} "PENDING"{"[PENDING]"} default{"[INFO]"} }
    $line = "[$ts] $tag $Message"
    if ($script:LogBox -and -not $script:LogBox.IsDisposed) {
        $color = switch ($Level) { "OK"{$GREEN} "FAIL"{$RED} "WARN"{$YELLOW} "PENDING"{$YELLOW} "SKIP"{$GRAY} default{$WHITE} }
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.SelectionColor = $color
        $script:LogBox.AppendText($line + [Environment]::NewLine)
        $script:LogBox.ScrollToCaret()
    }
    try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch {}
    $script:LogEntries.Add([pscustomobject]@{ Time=(Get-Date -Format "yyyy-MM-dd HH:mm:ss"); Level=$Level; Message=$Message })
}

# ---------------------------------------------------------------------
# Low-level readers
# ---------------------------------------------------------------------
function Get-BcdValue([string]$Name) {
    try {
        $lines = & bcdedit.exe /enum "{current}" 2>$null
        foreach ($line in $lines) { if ($line -match "^\s*$Name\s+(.+?)\s*$") { return $Matches[1].Trim() } }
    } catch {}
    return "Unknown"
}
function Get-FeatureState([string]$Name) {
    try { return (Get-WindowsOptionalFeature -Online -FeatureName $Name -ErrorAction Stop).State.ToString() }
    catch { return "Unknown" }
}
function Test-RebootPending {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )
    foreach ($p in $paths) { if (Test-Path $p) { return $true } }
    try {
        $v = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction Stop
        if ($v) { return $true }
    } catch {}
    return $false
}

function Get-Diagnostics {
    $d = [ordered]@{}
    $d.TestSigning = Get-BcdValue "testsigning"
    $d.NoIntegrityChecks = Get-BcdValue "nointegritychecks"
    $d.HypervisorLaunchType = Get-BcdValue "hypervisorlaunchtype"

    try { $d.HypervisorPresent = [bool](Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).HypervisorPresent }
    catch { $d.HypervisorPresent = $false }

    try {
        $dg = Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName Win32_DeviceGuard -ErrorAction Stop
        $d.VBSStatus = [int]$dg.VirtualizationBasedSecurityStatus
        $running = @($dg.SecurityServicesRunning)
        $d.CredentialGuardRunning = ($running -contains 1)
        $d.HVCIRunningViaVBS = ($running -contains 2)
    } catch {
        $d.VBSStatus = -1; $d.CredentialGuardRunning = $false; $d.HVCIRunningViaVBS = $false
    }

    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
        $d.HVCIConfigured = [int](Get-ItemProperty -Path $p -ErrorAction Stop).Enabled
    } catch { $d.HVCIConfigured = 0 }

    try {
        $p = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
        $d.VBSConfigured = [int](Get-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity -ErrorAction Stop).EnableVirtualizationBasedSecurity
    } catch { $d.VBSConfigured = 0 }

    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        $d.DefenderAV = [bool]$mp.AntivirusEnabled
        $d.DefenderRealTime = [bool]$mp.RealTimeProtectionEnabled
        $d.DefenderBehavior = [bool]$mp.BehaviorMonitorEnabled
        $d.DefenderIOAV = [bool]$mp.IoavProtectionEnabled
        $d.DefenderNIS = [bool]$mp.NISEnabled
    } catch {
        $d.DefenderAV=$false; $d.DefenderRealTime=$false; $d.DefenderBehavior=$false; $d.DefenderIOAV=$false; $d.DefenderNIS=$false
    }

    try {
        $fw = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($prof in $fw) { $d["Firewall_$($prof.Name)"] = [bool]$prof.Enabled }
    } catch { $d.Firewall_Domain=$null; $d.Firewall_Private=$null; $d.Firewall_Public=$null }

    try { $d.SecureBoot = [bool](Confirm-SecureBootUEFI -ErrorAction Stop); $d.SecureBootAvailable = $true }
    catch { $d.SecureBoot = $null; $d.SecureBootAvailable = $false }

    $d.RebootPending = Test-RebootPending

    $d.VirtualMachinePlatform = Get-FeatureState "VirtualMachinePlatform"
    $d.HypervisorPlatform = Get-FeatureState "HypervisorPlatform"
    $d.WSL = Get-FeatureState "Microsoft-Windows-Subsystem-Linux"
    $d.HyperV = Get-FeatureState "Microsoft-Hyper-V-All"

    try { $d.NetAdaptersUp = @(Get-NetAdapter -ErrorAction Stop | Where-Object {$_.Status -eq "Up"}).Count }
    catch { $d.NetAdaptersUp = $null }

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $d.OSCaption = $os.Caption; $d.OSVersion = $os.Version
    } catch { $d.OSCaption = "Unknown"; $d.OSVersion = "Unknown" }

    return [pscustomobject]$d
}

# DSE is inferred, never read from a single flag - documented explicitly.
function Get-DSEState($D) {
    if ($D.TestSigning -eq "Yes") { return @{Code="WEAK";NotePT="Reduzida: drivers assinados por teste sao aceitos (Test Signing ON).";NoteEN="Reduced: test-signed drivers are accepted (Test Signing ON)."} }
    if ($D.NoIntegrityChecks -eq "Yes") { return @{Code="WEAK";NotePT="Reduzida por NoIntegrityChecks (efeito limitado em builds recentes).";NoteEN="Reduced via NoIntegrityChecks (limited effect on recent builds)."} }
    if ($D.TestSigning -eq "No" -and $D.NoIntegrityChecks -eq "No") { return @{Code="ON";NotePT="Padrao: apenas drivers assinados sao carregados.";NoteEN="Standard: only signed drivers are loaded."} }
    return @{Code="UNK";NotePT="Nao foi possivel confirmar de forma confiavel.";NoteEN="Could not be reliably confirmed."}
}

function Get-Environment($D) {
    $notes = New-Object System.Collections.Generic.List[string]
    $testFlags = ($D.TestSigning -eq "Yes") -or ($D.NoIntegrityChecks -eq "Yes")
    $hvciOn = ($D.HVCIConfigured -eq 1) -and $D.HVCIRunningViaVBS
    $vbsOn = ($D.VBSStatus -eq 2)
    $protectedCore = $vbsOn -and $hvciOn -and (-not $testFlags)

    $fwAll = $true
    foreach ($k in @("Firewall_Domain","Firewall_Private","Firewall_Public")) {
        if ($D.PSObject.Properties.Name -contains $k) { if ($D.$k -eq $false) { $fwAll=$false; $notes.Add("Firewall") } }
    }
    if (-not $D.DefenderRealTime) { $notes.Add("Defender") }

    if ($testFlags -and $protectedCore -eq $false) {
        if (-not $fwAll -or -not $D.DefenderRealTime) { return @{State="MIXED";Notes=$notes} }
        return @{State="TEST";Notes=$notes}
    }
    if ($protectedCore -and $fwAll -and $D.DefenderRealTime) { return @{State="PROTECTED";Notes=$notes} }
    if ($testFlags -or (-not $hvciOn) -or (-not $vbsOn) -or (-not $fwAll) -or (-not $D.DefenderRealTime)) {
        return @{State="MIXED";Notes=$notes}
    }
    return @{State="UNKNOWN";Notes=$notes}
}

# ---------------------------------------------------------------------
# Diagnostics grid rows
# ---------------------------------------------------------------------
function StateCell($Code) {
    switch ($Code) {
        "ON" { return @{Text=(Tx "StateON");Color=$GREEN} }
        "OFF" { return @{Text=(Tx "StateOFF");Color=$RED} }
        "NA" { return @{Text=(Tx "StateNA");Color=$GRAY} }
        "MANUAL" { return @{Text=(Tx "StateMANUAL");Color=$YELLOW} }
        "PENDING" { return @{Text=(Tx "StatePENDING");Color=$YELLOW} }
        "WEAK" { return @{Text=(Tx "StateOFF");Color=$YELLOW} }
        default { return @{Text=(Tx "StateUNK");Color=$GRAY} }
    }
}
function B2Code($b) { if ($b -eq $null) { return "UNK" }; if ($b) { return "ON" } else { return "OFF" } }

function Build-DiagRows($D) {
    $rows = New-Object System.Collections.Generic.List[object]
    $add = { param($Name,$Code,$Source,$Note) $rows.Add([pscustomobject]@{Name=$Name;Code=$Code;Source=$Source;Note=$Note}) }

    & $add "Test Signing" $(if($D.TestSigning -eq "Yes"){"ON"}elseif($D.TestSigning -eq "No"){"OFF"}else{"UNK"}) "bcdedit" ""
    & $add $(if($script:Lang -eq "PT"){"Verificacao de Integridade"}else{"Integrity Checks"}) $(if($D.NoIntegrityChecks -eq "Yes"){"OFF"}elseif($D.NoIntegrityChecks -eq "No"){"ON"}else{"UNK"}) "bcdedit" ""
    $dse = Get-DSEState $D
    & $add "DSE (Driver Signature Enforcement)" $dse.Code "inferido" $(if($script:Lang -eq "PT"){$dse.NotePT}else{$dse.NoteEN})
    & $add $(if($script:Lang -eq "PT"){"Hipervisor do Windows"}else{"Windows Hypervisor"}) (B2Code $D.HypervisorPresent) "CIM" ""
    & $add "Hypervisor Launch Type" $(if($D.HypervisorLaunchType -eq "Off"){"OFF"}elseif($D.HypervisorLaunchType -eq "Auto"){"ON"}else{"UNK"}) "bcdedit" ""
    & $add "VBS" $(if($D.VBSStatus -eq 2){"ON"}elseif($D.VBSStatus -eq 0){"OFF"}else{"UNK"}) "DeviceGuard" ""
    & $add "Credential Guard" (B2Code $D.CredentialGuardRunning) "DeviceGuard" ""
    $hvciCode = if ($D.HVCIConfigured -eq 1 -and $D.HVCIRunningViaVBS) {"ON"} elseif ($D.HVCIConfigured -eq 1 -and -not $D.HVCIRunningViaVBS) {"PENDING"} else {"OFF"}
    & $add $(if($script:Lang -eq "PT"){"Integridade de Memoria (HVCI)"}else{"Memory Integrity (HVCI)"}) $hvciCode "Registro+DeviceGuard" ""
    & $add "Microsoft Defender (Real-Time)" (B2Code $D.DefenderRealTime) "Get-MpComputerStatus" ""
    & $add "Defender Behavior/IOAV/NIS" (B2Code ($D.DefenderBehavior -and $D.DefenderIOAV -and $D.DefenderNIS)) "Get-MpComputerStatus" ""
    foreach ($prof in @("Domain","Private","Public")) {
        $k = "Firewall_$prof"
        $v = $null; if ($D.PSObject.Properties.Name -contains $k) { $v = $D.$k }
        & $add "Firewall ($prof)" (B2Code $v) "Get-NetFirewallProfile" ""
    }
    if ($D.SecureBootAvailable) {
        & $add "Secure Boot" (B2Code $D.SecureBoot) "Confirm-SecureBootUEFI" $(if($script:Lang -eq "PT"){"Depende de firmware BIOS/UEFI."}else{"Depends on BIOS/UEFI firmware."})
    } else {
        & $add "Secure Boot" "NA" "Confirm-SecureBootUEFI" $(if($script:Lang -eq "PT"){"Nao suportado/legado. Depende de firmware BIOS/UEFI."}else{"Not supported/legacy. Depends on BIOS/UEFI firmware."})
    }
    & $add $(if($script:Lang -eq "PT"){"Reinicializacao Pendente"}else{"Reboot Pending"}) (B2Code $D.RebootPending) "Registro" ""
    foreach ($f in @(@("VirtualMachinePlatform","Virtual Machine Platform"),@("HypervisorPlatform","Hypervisor Platform"),@("WSL","WSL"),@("HyperV","Hyper-V"))) {
        $val = $D.($f[0])
        $code = if ($val -eq "Enabled") {"ON"} elseif ($val -eq "Disabled") {"OFF"} else {"UNK"}
        & $add $f[1] $code "Get-WindowsOptionalFeature" ""
    }
    $netTxt = if ($D.NetAdaptersUp -ne $null) { "$($D.NetAdaptersUp) " + (Tx "NetSummary") } else { Tx "StateUNK" }
    & $add $(if($script:Lang -eq "PT"){"Rede"}else{"Network"}) "INFO" "Get-NetAdapter" $netTxt

    return $rows
}

function Render-DiagGrid($D) {
    $grid = $script:DiagGrid
    $grid.Rows.Clear()
    foreach ($r in (Build-DiagRows $D)) {
        $cell = StateCell $r.Code
        if ($r.Code -eq "INFO") { $cell = @{Text=$r.Note;Color=$GRAY} }
        $idx = $grid.Rows.Add($r.Name, $cell.Text, $r.Source, $(if($r.Code -eq "INFO"){""}else{$r.Note}))
        $grid.Rows[$idx].Cells[1].Style.ForeColor = $cell.Color
    }
}

# ---------------------------------------------------------------------
# Refresh (read-only)
# ---------------------------------------------------------------------
function Refresh-UI {
    if ($script:Busy) { return }
    $script:Busy = $true
    try {
        Write-Log $(if($script:Lang -eq "PT"){"Diagnostico iniciado."}else{"Diagnostics started."})
        $script:Diag = Get-Diagnostics
        Render-DiagGrid $script:Diag
        $envResult = Get-Environment $script:Diag
        $script:State = $envResult.State
        switch ($script:State) {
            "PROTECTED" { $script:EnvironmentLabel.Text = Tx "EnvProtected"; $script:EnvironmentLabel.ForeColor = $GREEN }
            "TEST"      { $script:EnvironmentLabel.Text = Tx "EnvTest"; $script:EnvironmentLabel.ForeColor = $ORANGE }
            "MIXED"     { $script:EnvironmentLabel.Text = Tx "EnvMixed"; $script:EnvironmentLabel.ForeColor = $YELLOW }
            default     { $script:EnvironmentLabel.Text = Tx "EnvUnknown"; $script:EnvironmentLabel.ForeColor = $YELLOW }
        }
        $script:BtnEnterTest.Enabled = ($script:State -ne "TEST")
        $script:BtnRestore.Enabled = ($script:State -ne "PROTECTED")
        Write-Log $(if($script:Lang -eq "PT"){"Diagnostico concluido. Estado: $($script:State)."}else{"Diagnostics complete. State: $($script:State)."}) "OK"
    } catch {
        Write-Log "$_" "FAIL"
    } finally { $script:Busy = $false }
}

# ---------------------------------------------------------------------
# Progress bar
# ---------------------------------------------------------------------
function Set-Progress([int]$Percent,[string]$Text) {
    $script:ProgressBar.Value = [Math]::Min(100,[Math]::Max(0,$Percent))
    $script:ProgressLabel.Text = "$Text ($Percent%)"
    [System.Windows.Forms.Application]::DoEvents()
}
function Reset-Progress { Set-Progress 0 (Tx "ProgressIdle") }

# ---------------------------------------------------------------------
# Plan dialog (shared by Enter-TestMode and Restore-Protected)
# Returns @{Confirmed=bool; HypervOff=bool}
# ---------------------------------------------------------------------
function Show-PlanDialog([string]$TitleKey,[string]$IntroKey,[object[]]$Changes,[bool]$OfferHypervOption,[bool]$ShowSecureBootWarn) {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx $TitleKey
    $f.Size = New-Object System.Drawing.Size(620,520)
    $f.StartPosition = "CenterParent"
    $f.FormBorderStyle = "FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor = $PANEL; $f.ForeColor = $WHITE

    $intro = New-Label (Tx $IntroKey) 16 14 580 55 9 $WHITE
    $f.Controls.Add($intro)

    $list = New-Object System.Windows.Forms.ListBox
    $list.Location = New-Object System.Drawing.Point(16,76)
    $list.Size = New-Object System.Drawing.Size(580,230)
    $list.BackColor = [System.Drawing.Color]::FromArgb(7,7,7); $list.ForeColor = $WHITE
    $list.Font = New-Object System.Drawing.Font("Consolas",9)
    if ($Changes.Count -eq 0) { $list.Items.Add((Tx "PlanNoChanges")) | Out-Null }
    foreach ($c in $Changes) {
        $reb = if ($c.Reboot) { Tx "PlanRebootYes" } else { Tx "PlanRebootNo" }
        $list.Items.Add("- $($c.Item): $($c.From) -> $($c.To)  [$($c.Method) | $reb]") | Out-Null
    }
    $f.Controls.Add($list)

    $y = 314
    $cbHyperv = New-Object System.Windows.Forms.CheckBox
    if ($OfferHypervOption) {
        $cbHyperv.Text = Tx "PlanOptHyperv"; $cbHyperv.ForeColor=$WHITE; $cbHyperv.Location=New-Object System.Drawing.Point(16,$y)
        $cbHyperv.Size = New-Object System.Drawing.Size(580,20); $f.Controls.Add($cbHyperv)
        $warn = New-Label (Tx "PlanOptHypervWarn") 36 ($y+20) 560 32 8 $YELLOW
        $f.Controls.Add($warn)
        $y += 56
    }
    if ($ShowSecureBootWarn) {
        $sbWarn = New-Label (Tx "PlanSecureBootWarn") 16 $y 580 46 9 $YELLOW
        $f.Controls.Add($sbWarn)
        $y += 50
    }

    $btnCancel = New-Button (Tx "BtnCancel") 340 430 110 38
    $btnOk = New-Button (Tx "BtnConfirmTest") 460 430 136 38
    $btnOk.BackColor = [System.Drawing.Color]::FromArgb(55,35,10)
    $f.Controls.AddRange(@($btnCancel,$btnOk))

    $script:_planResult = @{Confirmed=$false; HypervOff=$false}
    $btnCancel.Add_Click({ $f.Tag = "cancel"; $f.Close() })
    $btnOk.Add_Click({
        $script:_planResult.Confirmed = $true
        if ($OfferHypervOption) { $script:_planResult.HypervOff = $cbHyperv.Checked }
        $f.Tag = "ok"; $f.Close()
    })
    [void]$f.ShowDialog()
    return $script:_planResult
}

# ---------------------------------------------------------------------
# Countdown reboot (cancelable, in-app - shutdown.exe only called at 0)
# ---------------------------------------------------------------------
function Start-CountdownReboot([int]$Seconds=10) {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "CountdownTitle"; $f.Size = New-Object System.Drawing.Size(420,180)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE; $f.TopMost=$true

    $lbl = New-Label ((Tx "CountdownMsg") + " $Seconds s") 20 24 380 30 13 $ORANGE
    $f.Controls.Add($lbl)
    $btnCancel = New-Button (Tx "CountdownCancel") 110 90 200 38
    $f.Controls.Add($btnCancel)

    $script:_rebootCanceled = $false
    $btnCancel.Add_Click({ $script:_rebootCanceled = $true; $timer.Stop(); $f.Close() })

    $remaining = $Seconds
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $script:_cdRemaining--
        if ($script:_cdRemaining -le 0) {
            $timer.Stop(); $f.Close()
        } else {
            $lbl.Text = (Tx "CountdownMsg") + " $($script:_cdRemaining) s"
        }
    })
    $script:_cdRemaining = $Seconds
    $timer.Start()
    [void]$f.ShowDialog()
    $timer.Dispose()

    if ($script:_rebootCanceled) {
        Write-Log (Tx "CountdownCanceled") "WARN"
        return $false
    }
    Write-Log $(if($script:Lang -eq "PT"){"Reinicializacao confirmada pelo usuario."}else{"Restart confirmed by user."}) "OK"
    Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 0" -Verb RunAs
    return $true
}

# ---------------------------------------------------------------------
# Scheduled tasks: reminder / auto-restore
# ---------------------------------------------------------------------
function New-HWuPScheduledTask([string]$Name,[datetime]$At,[string]$Action) {
    $dateStr = $At.ToString("MM/dd/yyyy"); $timeStr = $At.ToString("HH:mm")
    if ($Action -eq "Reminder") {
        $msg = if ($script:Lang -eq "PT") { "HWuP: voce ainda esta no Ambiente de Teste. Considere voltar ao ambiente protegido." } else { "HWuP: you are still in Test Mode. Consider returning to the protected environment." }
        $tr = "msg.exe * `"$msg`""
    } else {
        $tr = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$script:ScriptSelf`" -AutoRestore"
    }
    & schtasks.exe /create /tn $Name /tr $tr /sc once /sd $dateStr /st $timeStr /f | Out-Null
    return ($LASTEXITCODE -eq 0)
}
function Remove-HWuPScheduledTask([string]$Name) {
    & schtasks.exe /delete /tn $Name /f 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}
function Get-HWuPScheduledTasks {
    $names = @("HWuP-Reminder","HWuP-AutoRestore")
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($n in $names) {
        & schtasks.exe /query /tn $n 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $found.Add($n) }
    }
    return $found
}

function Show-ReminderPrompt {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "ReminderTitle"; $f.Size = New-Object System.Drawing.Size(440,300)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE

    $intro = New-Label (Tx "ReminderIntro") 16 14 400 40 9 $WHITE
    $f.Controls.Add($intro)
    $opts = @(@("r1",(Tx "Rem1h")),@("r2",(Tx "Rem2h")),@("r3",(Tx "Rem3h")),@("auto",(Tx "RemAuto")),@("none",(Tx "RemNone")))
    $radios = @{}
    $y = 60
    foreach ($o in $opts) {
        $rb = New-Object System.Windows.Forms.RadioButton
        $rb.Text = $o[1]; $rb.ForeColor=$WHITE; $rb.Location=New-Object System.Drawing.Point(20,$y)
        $rb.Size = New-Object System.Drawing.Size(380,22)
        $f.Controls.Add($rb); $radios[$o[0]] = $rb
        $y += 26
    }
    $radios["none"].Checked = $true
    $note = New-Label (Tx "RemNote") 16 ($y+4) 400 40 8 $GRAY
    $f.Controls.Add($note)
    $btnOk = New-Button (Tx "BtnConfirmSmall") 150 230 140 36
    $f.Controls.Add($btnOk)
    $script:_remChoice = "none"
    $btnOk.Add_Click({
        foreach ($k in $radios.Keys) { if ($radios[$k].Checked) { $script:_remChoice = $k } }
        $f.Close()
    })
    [void]$f.ShowDialog()
    return $script:_remChoice
}

function Apply-ReminderChoice([string]$Choice) {
    Remove-HWuPScheduledTask "HWuP-Reminder" | Out-Null
    Remove-HWuPScheduledTask "HWuP-AutoRestore" | Out-Null
    $hours = switch ($Choice) { "r1"{1} "r2"{2} "r3"{3} "auto"{1} default{0} }
    if ($hours -eq 0) { return }
    $at = (Get-Date).AddHours($hours)
    if ($Choice -eq "auto") {
        if (New-HWuPScheduledTask "HWuP-AutoRestore" $at "AutoRestore") {
            Write-Log $(if($script:Lang -eq "PT"){"Retorno automatico agendado para $at."}else{"Auto-restore scheduled for $at."}) "OK"
        } else { Write-Log $(if($script:Lang -eq "PT"){"Falha ao agendar retorno automatico."}else{"Failed to schedule auto-restore."}) "FAIL" }
    } else {
        if (New-HWuPScheduledTask "HWuP-Reminder" $at "Reminder") {
            Write-Log $(if($script:Lang -eq "PT"){"Lembrete agendado para $at."}else{"Reminder scheduled for $at."}) "OK"
        } else { Write-Log $(if($script:Lang -eq "PT"){"Falha ao agendar lembrete."}else{"Failed to schedule reminder."}) "FAIL" }
    }
}

function Show-RemindersDialog {
    $tasks = Get-HWuPScheduledTasks
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "RemindersListTitle"; $f.Size = New-Object System.Drawing.Size(420,280)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE
    if ($tasks.Count -eq 0) {
        $f.Controls.Add((New-Label (Tx "RemindersNone") 20 20 360 40 10 $GRAY))
    } else {
        $y = 20
        foreach ($t in $tasks) {
            $f.Controls.Add((New-Label $t 20 $y 220 26 10 $WHITE))
            $btnRm = New-Button (Tx "BtnRemoveTask") 250 ($y-2) 130 30
            $tCapture = $t
            $btnRm.Add_Click({ Remove-HWuPScheduledTask $tCapture | Out-Null; Write-Log "$tCapture removed." "OK"; $f.Close() }.GetNewClosure())
            $f.Controls.Add($btnRm)
            $y += 36
        }
    }
    $btnClose = New-Button (Tx "BtnClose") 140 200 140 36
    $btnClose.Add_Click({ $f.Close() })
    $f.Controls.Add($btnClose)
    [void]$f.ShowDialog()
}

# ---------------------------------------------------------------------
# Enter Test Mode
# ---------------------------------------------------------------------
function Get-UpNetworkAdapters {
    try { return @(Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq "Up" }) }
    catch { return @() }
}

# Shows a checklist of active adapters; returns an array of adapter names to disable (empty = keep network).
function Show-NetworkChoiceDialog {
    $adapters = Get-UpNetworkAdapters
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "NetDlgTitle"; $f.Size = New-Object System.Drawing.Size(480,380)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE

    $intro = New-Label (Tx "NetDlgIntro") 16 14 440 60 9 $WHITE
    $f.Controls.Add($intro)

    $checks = @()
    if ($adapters.Count -eq 0) {
        $f.Controls.Add((New-Label (Tx "NetDlgNone") 20 90 400 24 9 $GRAY))
    } else {
        $y = 90
        foreach ($a in $adapters) {
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = "$($a.Name) - $($a.InterfaceDescription)"
            $cb.ForeColor=$WHITE; $cb.Location=New-Object System.Drawing.Point(20,$y)
            $cb.Size = New-Object System.Drawing.Size(430,22); $cb.Tag = $a.Name
            $f.Controls.Add($cb); $checks += $cb
            $y += 26
        }
    }

    $btnOk = New-Button (Tx "BtnConfirmSmall") 170 300 140 36
    $f.Controls.Add($btnOk)
    $script:_netChoice = @()
    $btnOk.Add_Click({
        $script:_netChoice = @($checks | Where-Object { $_.Checked } | ForEach-Object { $_.Tag })
        $f.Close()
    })
    [void]$f.ShowDialog()
    return $script:_netChoice
}

function Apply-NetworkChoice([string[]]$NamesToDisable) {
    if (-not $NamesToDisable -or $NamesToDisable.Count -eq 0) { return }
    $disabled = New-Object System.Collections.Generic.List[string]
    foreach ($n in $NamesToDisable) {
        try {
            Disable-NetAdapter -Name $n -Confirm:$false -ErrorAction Stop
            $disabled.Add($n)
            Write-Log "$(if($script:Lang -eq 'PT'){'Adaptador desativado'}else{'Adapter disabled'}): $n" "OK"
        } catch {
            Write-Log "$(if($script:Lang -eq 'PT'){'Falha ao desativar adaptador'}else{'Failed to disable adapter'}) $n : $_" "FAIL"
        }
    }
    if ($disabled.Count -gt 0) {
        $st = Get-HWuPState; $st.DisabledAdaptersByHWuP = @($disabled); Save-HWuPState $st
    }
}

function Show-ReactivateNetworkDialog {
    $st = Get-HWuPState
    $names = @($st.DisabledAdaptersByHWuP)
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "ReactivateTitle"; $f.Size = New-Object System.Drawing.Size(460,320)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE

    if ($names.Count -eq 0) {
        $f.Controls.Add((New-Label (Tx "ReactivateNone") 20 20 400 40 10 $GRAY))
        $btnClose = New-Button (Tx "BtnClose") 150 200 140 36
        $btnClose.Add_Click({ $f.Close() })
        $f.Controls.Add($btnClose)
        [void]$f.ShowDialog()
        return
    }

    $f.Controls.Add((New-Label (Tx "ReactivateIntro") 16 14 420 36 9 $WHITE))
    $y = 56
    foreach ($n in $names) { $f.Controls.Add((New-Label "- $n" 30 $y 380 22 10 $WHITE)); $y += 24 }

    $btnOk = New-Button (Tx "BtnConfirmReactivate") 140 ($y+20) 180 38
    $f.Controls.Add($btnOk)
    $btnOk.Add_Click({
        foreach ($n in $names) {
            try {
                Enable-NetAdapter -Name $n -Confirm:$false -ErrorAction Stop
                Write-Log "$(if($script:Lang -eq 'PT'){'Adaptador reativado'}else{'Adapter reactivated'}): $n" "OK"
            } catch {
                Write-Log "$(if($script:Lang -eq 'PT'){'Falha ao reativar adaptador'}else{'Failed to reactivate adapter'}) $n : $_" "FAIL"
            }
        }
        $st2 = Get-HWuPState; $st2.DisabledAdaptersByHWuP = @(); Save-HWuPState $st2
        Update-NetworkButton
        $f.Close()
    })
    [void]$f.ShowDialog()
}

function Update-NetworkButton {
    $st = Get-HWuPState
    $n = @($st.DisabledAdaptersByHWuP).Count
    if ($n -gt 0) {
        $script:BtnNetwork.Enabled = $true
        $script:BtnNetwork.Text = (Tx "BtnReactivateNetwork") + " ($n)"
    } else {
        $script:BtnNetwork.Enabled = $false
        $script:BtnNetwork.Text = Tx "BtnReactivateNetwork"
    }
}

function Enter-TestMode {
    if ($script:Busy) { return }
    $D = Get-Diagnostics
    $changes = New-Object System.Collections.Generic.List[object]
    if ($D.TestSigning -ne "Yes") { $changes.Add([pscustomobject]@{Item="Test Signing";From=$D.TestSigning;To="On";Method=(Tx "PlanAuto");Reboot=$true;Key="TS"}) }
    if ($D.NoIntegrityChecks -ne "Yes") { $changes.Add([pscustomobject]@{Item="NoIntegrityChecks";From=$D.NoIntegrityChecks;To="On";Method=(Tx "PlanAuto");Reboot=$true;Key="NIC"}) }
    if (-not ($D.VBSConfigured -eq 0)) { $changes.Add([pscustomobject]@{Item="VBS";From="On";To="Off";Method=(Tx "PlanAuto");Reboot=$true;Key="VBS"}) }
    if (-not ($D.HVCIConfigured -eq 0)) { $changes.Add([pscustomobject]@{Item="HVCI";From="On";To="Off";Method=(Tx "PlanAuto");Reboot=$true;Key="HVCI"}) }

    $plan = Show-PlanDialog "PlanTitleTest" "PlanIntroTest" $changes $true $D.SecureBoot
    if (-not $plan.Confirmed) { Write-Log $(if($script:Lang -eq "PT"){"Entrada em Modo de Teste cancelada pelo usuario."}else{"Enter Test Mode canceled by user."}) "SKIP"; return }

    $script:Busy = $true
    try {
        $steps = New-Object System.Collections.Generic.List[object]
        foreach ($c in $changes) { $steps.Add($c) }
        if ($plan.HypervOff) { $steps.Add([pscustomobject]@{Item="hypervisorlaunchtype";From=$D.HypervisorLaunchType;To="Off";Method=(Tx "PlanAuto");Reboot=$true;Key="HVLT"}) }
        if ($steps.Count -eq 0) {
            Write-Log $(if($script:Lang -eq "PT"){"Nada a alterar: ja em conformidade com o perfil de teste."}else{"Nothing to change: already matches the test profile."}) "SKIP"
            Set-Progress 100 (Tx "ProgressIdle"); return
        }
        $i = 0; $total = $steps.Count
        foreach ($s in $steps) {
            $i++
            Set-Progress ([int](($i-1)/$total*100)) $s.Item
            switch ($s.Key) {
                "TS" { & bcdedit.exe /set testsigning on | Out-Null; $ok = ($LASTEXITCODE -eq 0) -and ((Get-BcdValue "testsigning") -eq "Yes") }
                "NIC" { & bcdedit.exe /set nointegritychecks on | Out-Null; $ok = ($LASTEXITCODE -eq 0) -and ((Get-BcdValue "nointegritychecks") -eq "Yes") }
                "VBS" {
                    try {
                        $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
                        Set-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity -Type DWord -Value 0 -Force -ErrorAction Stop
                        $ok = ((Get-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity).EnableVirtualizationBasedSecurity -eq 0)
                    } catch { $ok = $false }
                }
                "HVCI" {
                    try {
                        $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
                        Set-ItemProperty -Path $p -Name Enabled -Type DWord -Value 0 -Force -ErrorAction Stop
                        $ok = ((Get-ItemProperty -Path $p -Name Enabled).Enabled -eq 0)
                    } catch { $ok = $false }
                }
                "HVLT" {
                    & bcdedit.exe /set hypervisorlaunchtype off | Out-Null
                    $ok = ($LASTEXITCODE -eq 0) -and ((Get-BcdValue "hypervisorlaunchtype") -eq "Off")
                    if ($ok) { $st = Get-HWuPState; $st.HypervisorLaunchTypeChangedByHWuP = $true; Save-HWuPState $st }
                }
                default { $ok = $false }
            }
            if ($ok) { Write-Log "$($s.Item): $($s.From) -> $($s.To)" "OK" } else { Write-Log "$($s.Item): $(if($script:Lang -eq 'PT'){'falhou'}else{'failed'})" "FAIL" }
        }
        Set-Progress 100 (Tx "ProgressIdle")
        $st = Get-HWuPState; $st.LastProfileApplied = "TEST"; $st.LastAppliedAt = (Get-Date).ToString("o"); Save-HWuPState $st

        $rem = Show-ReminderPrompt
        Apply-ReminderChoice $rem

        $netChoice = Show-NetworkChoiceDialog
        Apply-NetworkChoice $netChoice
        Update-NetworkButton

        Start-CountdownReboot 10 | Out-Null
    } finally { $script:Busy = $false }
}

# ---------------------------------------------------------------------
# Restore Protected Mode
# ---------------------------------------------------------------------
function Restore-Protected {
    if ($script:Busy) { return }
    $D = Get-Diagnostics
    $changes = New-Object System.Collections.Generic.List[object]
    if ($D.TestSigning -eq "Yes") { $changes.Add([pscustomobject]@{Item="Test Signing";From="On";To="Off";Method=(Tx "PlanAuto");Reboot=$true;Key="TS"}) }
    if ($D.NoIntegrityChecks -eq "Yes") { $changes.Add([pscustomobject]@{Item="NoIntegrityChecks";From="On";To="Off";Method=(Tx "PlanAuto");Reboot=$true;Key="NIC"}) }
    if (-not ($D.VBSConfigured -eq 1)) { $changes.Add([pscustomobject]@{Item="VBS";From="Off";To="On";Method=(Tx "PlanAuto");Reboot=$true;Key="VBS"}) }
    if (-not ($D.HVCIConfigured -eq 1)) { $changes.Add([pscustomobject]@{Item="HVCI";From="Off";To="On";Method=(Tx "PlanAuto");Reboot=$true;Key="HVCI"}) }
    foreach ($prof in @("Domain","Private","Public")) {
        $k = "Firewall_$prof"
        if (($D.PSObject.Properties.Name -contains $k) -and ($D.$k -eq $false)) {
            $changes.Add([pscustomobject]@{Item="Firewall ($prof)";From="Off";To="On";Method=(Tx "PlanAuto");Reboot=$false;Key="FW_$prof"})
        }
    }
    if (-not $D.DefenderRealTime) { $changes.Add([pscustomobject]@{Item="Defender Real-Time";From="Off";To="On";Method=(Tx "PlanAuto");Reboot=$false;Key="DEF"}) }
    $st0 = Get-HWuPState
    if ($st0.HypervisorLaunchTypeChangedByHWuP -and $D.HypervisorLaunchType -eq "Off") {
        $changes.Add([pscustomobject]@{Item="hypervisorlaunchtype";From="Off";To="Auto";Method=(Tx "PlanAuto");Reboot=$true;Key="HVLT"})
    }
    if ($D.SecureBootAvailable -and ($D.SecureBoot -eq $false)) {
        $changes.Add([pscustomobject]@{Item="Secure Boot";From="Off";To=(Tx "StateMANUAL");Method=(Tx "PlanManual");Reboot=$false;Key="SB_INFO"})
    }

    $plan = Show-PlanDialog "PlanTitleRestore" "PlanIntroRestore" $changes $false $false
    if (-not $plan.Confirmed) { Write-Log $(if($script:Lang -eq "PT"){"Restauracao cancelada pelo usuario."}else{"Restore canceled by user."}) "SKIP"; return }

    $script:Busy = $true
    try {
        $actionable = $changes | Where-Object { $_.Key -ne "SB_INFO" }
        if (@($actionable).Count -eq 0) {
            Write-Log $(if($script:Lang -eq "PT"){"Nada a alterar: ja em conformidade com o perfil protegido."}else{"Nothing to change: already matches the protected profile."}) "SKIP"
            Set-Progress 100 (Tx "ProgressIdle")
        } else {
            $i=0; $total=@($actionable).Count; $needsReboot=$false
            foreach ($s in $actionable) {
                $i++
                Set-Progress ([int](($i-1)/$total*100)) $s.Item
                $ok = $false
                switch -Wildcard ($s.Key) {
                    "TS" { & bcdedit.exe /set testsigning off | Out-Null; $ok=($LASTEXITCODE -eq 0) -and ((Get-BcdValue "testsigning") -eq "No") }
                    "NIC" { & bcdedit.exe /set nointegritychecks off | Out-Null; $ok=($LASTEXITCODE -eq 0) -and ((Get-BcdValue "nointegritychecks") -eq "No") }
                    "VBS" {
                        try { $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
                            Set-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity -Type DWord -Value 1 -Force -ErrorAction Stop
                            $ok = ((Get-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity).EnableVirtualizationBasedSecurity -eq 1)
                        } catch { $ok=$false }
                    }
                    "HVCI" {
                        try { $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}
                            Set-ItemProperty -Path $p -Name Enabled -Type DWord -Value 1 -Force -ErrorAction Stop
                            $ok = ((Get-ItemProperty -Path $p -Name Enabled).Enabled -eq 1)
                        } catch { $ok=$false }
                    }
                    "FW_*" {
                        $profName = $s.Key.Substring(3)
                        try { Set-NetFirewallProfile -Profile $profName -Enabled True -ErrorAction Stop
                            $ok = ((Get-NetFirewallProfile -Profile $profName).Enabled)
                        } catch { $ok=$false }
                    }
                    "DEF" {
                        try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
                            $ok = (Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled
                        } catch { $ok=$false; Write-Log $(if($script:Lang -eq "PT"){"Defender pode estar sob Tamper Protection/politica - ajuste manual pode ser necessario."}else{"Defender may be under Tamper Protection/policy - manual adjustment may be needed."}) "WARN" }
                    }
                    "HVLT" {
                        & bcdedit.exe /set hypervisorlaunchtype auto | Out-Null
                        $ok = ($LASTEXITCODE -eq 0) -and ((Get-BcdValue "hypervisorlaunchtype") -eq "Auto")
                        if ($ok) { $st=Get-HWuPState; $st.HypervisorLaunchTypeChangedByHWuP=$false; Save-HWuPState $st }
                    }
                }
                if ($s.Reboot) { $needsReboot = $true }
                if ($ok) { Write-Log "$($s.Item): $($s.From) -> $($s.To)" "OK" } else { Write-Log "$($s.Item): $(if($script:Lang -eq 'PT'){'falhou'}else{'failed'})" "FAIL" }
            }
            Set-Progress 100 (Tx "ProgressIdle")
        }
        if (($D.SecureBootAvailable) -and ($D.SecureBoot -eq $false)) {
            Write-Log $(if($script:Lang -eq "PT"){"Secure Boot continua desativado - requer acao manual na BIOS/UEFI."}else{"Secure Boot remains off - requires manual BIOS/UEFI action."}) "WARN"
        }
        $st = Get-HWuPState; $st.LastProfileApplied = "PROTECTED"; $st.LastAppliedAt = (Get-Date).ToString("o"); Save-HWuPState $st

        if ($needsReboot) {
            Start-CountdownReboot 10 | Out-Null
        } else {
            Refresh-UI
        }
    } finally { $script:Busy = $false }
}

# ---------------------------------------------------------------------
# Report export (TXT + JSON)
# ---------------------------------------------------------------------
function Export-Report {
    try {
        $folder = Join-Path $env:USERPROFILE "Desktop\HWuP-Reports"
        if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $base = Join-Path $folder "HWuP-Report-$stamp"
        $D = if ($script:Diag) { $script:Diag } else { Get-Diagnostics }
        $report = [ordered]@{
            HWuPVersion = "1.0.0 (Phase 1)"
            GeneratedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            OS = $D.OSCaption; OSVersion = $D.OSVersion
            Architecture = if ([Environment]::Is64BitOperatingSystem) {"x64"} else {"x86"}
            State = $script:State
            Diagnostics = $D
            Log = $script:LogEntries
        }
        $report | ConvertTo-Json -Depth 6 | Set-Content -Path "$base.json" -Encoding UTF8
        @(
            "HWuP Windows Environment Manager - Report"
            "Generated: $($report.GeneratedAt)"
            "State: $($report.State)"
            ""
            ($D | Format-List | Out-String)
            "--- LOG ---"
            ($script:LogEntries | ForEach-Object { "[$($_.Time)] [$($_.Level)] $($_.Message)" }) -join "`r`n"
        ) | Set-Content -Path "$base.txt" -Encoding ASCII
        Write-Log "$(Tx 'ReportSaved') $base.txt / .json" "OK"
        [System.Windows.Forms.MessageBox]::Show("$(Tx 'ReportSaved')`r`n$base.txt`r`n$base.json","HWuP",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        Write-Log "$(Tx 'ReportError'): $_" "FAIL"
        [System.Windows.Forms.MessageBox]::Show("$_","$(Tx 'ReportError')") | Out-Null
    }
}

# ---------------------------------------------------------------------
# About
# ---------------------------------------------------------------------
function Show-About {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = Tx "AboutTitle"; $f.Size = New-Object System.Drawing.Size(460,340)
    $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.BackColor=$PANEL; $f.ForeColor=$WHITE
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Multiline=$true; $txt.ReadOnly=$true; $txt.BorderStyle="None"
    $txt.BackColor=$PANEL; $txt.ForeColor=$WHITE; $txt.Font = New-Object System.Drawing.Font("Segoe UI",9)
    $txt.Location = New-Object System.Drawing.Point(16,14); $txt.Size = New-Object System.Drawing.Size(410,200)
    $txt.Text = Tx "AboutBody"
    $f.Controls.Add($txt)
    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Text = Tx "AboutLink"; $link.Location = New-Object System.Drawing.Point(16,220)
    $link.Size = New-Object System.Drawing.Size(410,24); $link.LinkColor=$ORANGE; $link.ActiveLinkColor=$WHITE
    $link.BackColor = $PANEL
    $link.Add_LinkClicked({ Start-Process (Tx "AboutLink") })
    $f.Controls.Add($link)
    $btnClose = New-Button (Tx "BtnClose") 160 260 140 36
    $btnClose.Add_Click({ $f.Close() })
    $f.Controls.Add($btnClose)
    [void]$f.ShowDialog()
}

# ---------------------------------------------------------------------
# AutoRestore mode (no GUI) - run by the scheduled task
# ---------------------------------------------------------------------
if ($AutoRestore) {
    try {
        $D = Get-Diagnostics
        $msg = if ($D.TestSigning -eq "Yes" -or $D.NoIntegrityChecks -eq "Yes") {
            & bcdedit.exe /set testsigning off | Out-Null
            & bcdedit.exe /set nointegritychecks off | Out-Null
            try { $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name EnableVirtualizationBasedSecurity -Type DWord -Value 1 -Force } catch {}
            try { $p="HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; if(-not(Test-Path $p)){New-Item -Path $p -Force|Out-Null}; Set-ItemProperty -Path $p -Name Enabled -Type DWord -Value 1 -Force } catch {}
            try { Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -ErrorAction Stop } catch {}
            $st = Get-HWuPState; $st.LastProfileApplied="PROTECTED"; $st.LastAppliedAt=(Get-Date).ToString("o"); Save-HWuPState $st
            "HWuP auto-restore applied."
        } else { "HWuP auto-restore: already protected." }
        Add-Content -Path (Join-Path $script:LogDir ("hwup-" + (Get-Date -Format "yyyyMMdd") + ".log")) -Value "[$(Get-Date -Format 'HH:mm:ss')] [AUTO] $msg"
        & schtasks.exe /delete /tn "HWuP-AutoRestore" /f 2>$null | Out-Null
        Start-Process -FilePath "shutdown.exe" -ArgumentList "/r /t 15" -Verb RunAs
    } catch {}
    exit
}

# =====================================================================
# Main form
# =====================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "HWuP - Windows Environment Manager"
$form.ClientSize = New-Object System.Drawing.Size(970,800)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.BackColor = $BG; $form.ForeColor = $WHITE
try { $icoPath = Join-Path (Split-Path -Parent $script:ScriptSelf) "hwup.ico"; if (Test-Path $icoPath) { $form.Icon = New-Object System.Drawing.Icon($icoPath) } } catch {}

$logo = New-Label "HWuP" 28 15 210 70 42 $ORANGE
$logo.Font = New-Object System.Drawing.Font("Segoe UI",42,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($logo)
$script:TitleLabel = New-Label (Tx "AppTitle") 240 27 560 38 18 $WHITE
$script:TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$form.Controls.Add($script:TitleLabel)
$script:SubLabel = New-Label (Tx "AppSub") 242 65 560 25 10 $GRAY
$form.Controls.Add($script:SubLabel)
$script:BtnLang = New-Button (Tx "BtnLang") 850 28 100 34
$form.Controls.Add($script:BtnLang)

$statePanel = New-Object System.Windows.Forms.Panel
$statePanel.Location = New-Object System.Drawing.Point(30,105); $statePanel.Size = New-Object System.Drawing.Size(910,56)
$statePanel.BackColor = $PANEL; $form.Controls.Add($statePanel)
$script:EnvLabelTitle = New-Label (Tx "EnvLabel") 18 6 500 20 9 $GRAY
$statePanel.Controls.Add($script:EnvLabelTitle)
$script:EnvironmentLabel = New-Label "..." 18 24 870 27 15 $YELLOW
$script:EnvironmentLabel.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$statePanel.Controls.Add($script:EnvironmentLabel)

$diagPanel = New-Object System.Windows.Forms.Panel
$diagPanel.Location = New-Object System.Drawing.Point(30,170); $diagPanel.Size = New-Object System.Drawing.Size(910,330)
$diagPanel.BackColor = $PANEL; $form.Controls.Add($diagPanel)
$script:DiagTitleLabel = New-Label (Tx "DiagTitle") 14 8 500 22 11 $WHITE
$diagPanel.Controls.Add($script:DiagTitleLabel)

$script:DiagGrid = New-Object System.Windows.Forms.DataGridView
$script:DiagGrid.Location = New-Object System.Drawing.Point(10,34)
$script:DiagGrid.Size = New-Object System.Drawing.Size(890,290)
$script:DiagGrid.BackgroundColor = $PANEL
$script:DiagGrid.BorderStyle = "None"
$script:DiagGrid.ReadOnly = $true
$script:DiagGrid.AllowUserToAddRows = $false
$script:DiagGrid.AllowUserToResizeRows = $false
$script:DiagGrid.RowHeadersVisible = $false
$script:DiagGrid.SelectionMode = "FullRowSelect"
$script:DiagGrid.ColumnHeadersDefaultCellStyle.BackColor = $PANEL2
$script:DiagGrid.ColumnHeadersDefaultCellStyle.ForeColor = $WHITE
$script:DiagGrid.DefaultCellStyle.BackColor = $PANEL
$script:DiagGrid.DefaultCellStyle.ForeColor = $WHITE
$script:DiagGrid.DefaultCellStyle.SelectionBackColor = $PANEL2
$script:DiagGrid.DefaultCellStyle.SelectionForeColor = $WHITE
$script:DiagGrid.GridColor = [System.Drawing.Color]::FromArgb(40,40,40)
$script:DiagGrid.EnableHeadersVisualStyles = $false
$script:DiagGrid.Columns.Add("c1",(Tx "ColName")) | Out-Null
$script:DiagGrid.Columns.Add("c2",(Tx "ColState")) | Out-Null
$script:DiagGrid.Columns.Add("c3",(Tx "ColSource")) | Out-Null
$script:DiagGrid.Columns.Add("c4",(Tx "ColNote")) | Out-Null
$script:DiagGrid.Columns[0].Width = 260; $script:DiagGrid.Columns[1].Width = 170
$script:DiagGrid.Columns[2].Width = 150; $script:DiagGrid.Columns[3].Width = 290
$diagPanel.Controls.Add($script:DiagGrid)

$progPanel = New-Object System.Windows.Forms.Panel
$progPanel.Location = New-Object System.Drawing.Point(30,512); $progPanel.Size = New-Object System.Drawing.Size(910,40)
$progPanel.BackColor = $PANEL; $form.Controls.Add($progPanel)
$script:ProgressLabel = New-Label (Tx "ProgressIdle") 12 4 400 16 8 $GRAY
$progPanel.Controls.Add($script:ProgressLabel)
$script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$script:ProgressBar.Location = New-Object System.Drawing.Point(12,22); $script:ProgressBar.Size = New-Object System.Drawing.Size(886,12)
$script:ProgressBar.Style = "Continuous"
$progPanel.Controls.Add($script:ProgressBar)

$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Location = New-Object System.Drawing.Point(30,560); $logPanel.Size = New-Object System.Drawing.Size(910,118)
$logPanel.BackColor = $PANEL; $form.Controls.Add($logPanel)
$script:LogTitleLabel = New-Label (Tx "LogTitle") 15 7 400 20 9 $GRAY
$logPanel.Controls.Add($script:LogTitleLabel)
$script:LogBox = New-Object System.Windows.Forms.RichTextBox
$script:LogBox.Location = New-Object System.Drawing.Point(15,28); $script:LogBox.Size = New-Object System.Drawing.Size(880,78)
$script:LogBox.ReadOnly = $true; $script:LogBox.BackColor = [System.Drawing.Color]::FromArgb(7,7,7)
$script:LogBox.ForeColor = $GRAY; $script:LogBox.BorderStyle = "None"; $script:LogBox.Font = New-Object System.Drawing.Font("Consolas",9)
$logPanel.Controls.Add($script:LogBox)

$script:BtnRefresh = New-Button (Tx "BtnRefresh") 30 690 140 42
$script:BtnEnterTest = New-Button (Tx "BtnEnterTest") 178 690 230 42
$script:BtnRestore = New-Button (Tx "BtnRestore") 416 690 240 42
$script:BtnReport = New-Button (Tx "BtnReport") 664 690 130 42
$script:BtnReminders = New-Button (Tx "BtnReminders") 802 690 138 42
$form.Controls.AddRange(@($script:BtnRefresh,$script:BtnEnterTest,$script:BtnRestore,$script:BtnReport,$script:BtnReminders))

$script:BtnNetwork = New-Button (Tx "BtnReactivateNetwork") 30 740 200 36
$script:BtnAbout = New-Button (Tx "BtnAbout") 700 740 110 36
$script:BtnExit = New-Button (Tx "BtnExit") 820 740 120 36
$form.Controls.AddRange(@($script:BtnNetwork,$script:BtnAbout,$script:BtnExit))

$script:BtnRefresh.Add_Click({ Refresh-UI })
$script:BtnEnterTest.Add_Click({ Enter-TestMode; Refresh-UI })
$script:BtnRestore.Add_Click({ Restore-Protected; Refresh-UI })
$script:BtnReport.Add_Click({ if (-not $script:Diag) { Refresh-UI }; Export-Report })
$script:BtnReminders.Add_Click({ Show-RemindersDialog })
$script:BtnNetwork.Add_Click({ Show-ReactivateNetworkDialog })
$script:BtnAbout.Add_Click({ Show-About })
$script:BtnExit.Add_Click({
    if ($script:Busy) {
        $r = [System.Windows.Forms.MessageBox]::Show((Tx "ExitBusyMsg"),(Tx "ExitBusyTitle"),[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    }
    $form.Close()
})
$script:BtnLang.Add_Click({
    $script:Lang = if ($script:Lang -eq "PT") { "EN" } else { "PT" }
    $script:TitleLabel.Text = Tx "AppTitle"; $script:SubLabel.Text = Tx "AppSub"; $script:BtnLang.Text = Tx "BtnLang"
    $script:EnvLabelTitle.Text = Tx "EnvLabel"; $script:DiagTitleLabel.Text = Tx "DiagTitle"; $script:LogTitleLabel.Text = Tx "LogTitle"
    $script:DiagGrid.Columns[0].HeaderText = Tx "ColName"; $script:DiagGrid.Columns[1].HeaderText = Tx "ColState"
    $script:DiagGrid.Columns[2].HeaderText = Tx "ColSource"; $script:DiagGrid.Columns[3].HeaderText = Tx "ColNote"
    $script:BtnRefresh.Text = Tx "BtnRefresh"; $script:BtnEnterTest.Text = Tx "BtnEnterTest"; $script:BtnRestore.Text = Tx "BtnRestore"
    $script:BtnReport.Text = Tx "BtnReport"; $script:BtnReminders.Text = Tx "BtnReminders"
    $script:BtnAbout.Text = Tx "BtnAbout"; $script:BtnExit.Text = Tx "BtnExit"
    Update-NetworkButton
    if ($script:Diag) { Refresh-UI } else { $script:ProgressLabel.Text = Tx "ProgressIdle" }
})

$form.Add_Shown({
    Write-Log $(if($script:Lang -eq "PT"){"HWuP iniciado."}else{"HWuP started."})
    Update-NetworkButton
    Refresh-UI
})
[void]$form.ShowDialog()
