# HWuP — Windows Environment Manager

![HWuP](hwup.png)

🇧🇷 [Português](#-português) · 🇺🇸 [English](#-english)

---

## 🇧🇷 Português

### O que é, em uma frase

Um programa com botão de "entrar em modo de teste" e botão de "voltar ao normal" para as proteções do Windows que atrapalham drivers não assinados, kernels customizados e ferramentas de overclock — e que nunca deixa você esquecer de religar tudo depois.

Se você já precisou desligar manualmente a assinatura de driver ou a Integridade de Memória pra rodar alguma ferramenta e ficou puto por ter que lembrar de religar na mão toda vez: é exatamente isso que o HWuP resolve.

### Funcionalidades

- **Diagnóstico real**, lido direto do sistema: Test Signing, DSE (explicado, não é uma flag só), VBS, HVCI/Core Isolation, Credential Guard, Microsoft Defender, Firewall por perfil, Secure Boot (com aviso de que depende da BIOS/UEFI), reinicialização pendente, Hyper-V/WSL/Virtual Machine Platform.
- **Entrar em Modo de Teste**: mostra o plano exato de mudanças antes de aplicar, pede confirmação, aplica, verifica cada item, pede reinicialização com contagem regressiva cancelável.
- **Restaurar Ambiente Protegido**: só mexe no que realmente está fora do perfil protegido — lê o estado antes, não manda comando às cegas.
- **Lembretes e retorno automático**: escolha ser lembrado em 1h/2h/3h, ou agende o retorno automático via Agendador de Tarefas do Windows. Nada disso é removido sozinho — só manualmente, pelo botão Lembretes.
- **Rede opcional durante o teste**: desativa só os adaptadores que você escolher, com botão de reativação sempre visível enquanto algo estiver desligado.
- **Relatório** em TXT e JSON com todo o diagnóstico e o log da sessão.
- **Monitor de estado**: dá pra usar só o diagnóstico, sem nunca entrar em modo de teste — painel de status de segurança do Windows no dia a dia.

### Casos de uso

- Desenvolvimento e teste de drivers Windows não assinados (WDK, kernel debugging).
- Ferramentas de overclock e tuning que dependem de kernel ou injetor próprio — ex.: **mVolt+** para desbloqueio de voltagem/clock em GPUs RTX série 50, e similares que exigem driver não assinado carregado.
- Testes em máquina virtual ou ambiente isolado com hipervisor/integridade de código configurados de forma específica.
- Pesquisa de segurança e engenharia reversa educacional, em ambiente controlado.
- Diagnóstico e monitoramento do estado de segurança do Windows, sem nunca sair do modo protegido.

### Uso responsável

O HWuP reduz deliberadamente proteções do Windows quando você pede, para viabilizar desenvolvimento, overclock e testes legítimos. Ele **não** foi feito para pirataria, para contornar anti-cheat, DRM ou qualquer proteção de jogos/softwares de terceiros, nem para violar termos de uso de plataformas. A HWuP não apoia nem endossa uso ilegal, pirataria ou bypass de proteção de jogos em hipótese alguma — mesmo sabendo que esse tipo de ambiente também é usado por terceiros para esses fins, essa nunca foi nem será a finalidade do projeto.

O HWuP nunca desativa Microsoft Defender, Firewall ou Secure Boot — em nenhum modo.

### Por que pedir admin e desativar proteções não é motivo pra desconfiar

**Em linguagem simples**: o Windows só deixa qualquer programa (inclusive o próprio Painel de Configurações do Windows) mudar essas proteções se ele estiver rodando como administrador. Isso não é um privilégio especial do HWuP, é a mesma exigência que o Windows faz pra qualquer um mexer nesse tipo de configuração — seja pelo HWuP, pelo Prompt de Comando ou pela tela de Segurança do Windows.

**Em linguagem técnica**: tudo que o HWuP faz é expor, numa interface com confirmação e log, comandos que a própria Microsoft documenta e disponibiliza oficialmente:

- `bcdedit /set testsigning on|off` é o mecanismo oficial da Microsoft para alternar o modo de teste de assinatura de driver, documentado em [learn.microsoft.com/windows-hardware/drivers/install/the-testsigning-boot-configuration-option](https://learn.microsoft.com/windows-hardware/drivers/install/the-testsigning-boot-configuration-option).
- Desligar e religar a Integridade de Memória (HVCI) e a Virtual Machine Platform **é uma funcionalidade suportada e recomendada pela própria Microsoft para jogadores**, documentada oficialmente em [support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613](https://support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613) — a Microsoft literalmente escreve: *"Gamers who want to prioritize performance have the option to turn off these features while gaming and turn them back on when finished"*. O HWuP automatiza exatamente esse ciclo, com verificação de que a reativação realmente aconteceu.
- A compilação usa **PS2EXE**, compilador de PowerShell-para-EXE open source de Markus Scholtes, código-fonte público em [github.com/MScholtes/PS2EXE](https://github.com/MScholtes/PS2EXE).

**Aviso honesto sobre falso-positivo de antivírus**: executáveis gerados por PS2EXE (e por ferramentas semelhantes) são frequentemente sinalizados por antivírus heurísticos — não porque o código seja malicioso, mas porque a técnica de empacotar um script em `.exe` também é usada por malware, e a heurística generaliza. Isso já é reconhecido publicamente pelo próprio mantenedor do PS2EXE. Por isso:

- O código-fonte (`HWuP.ps1`) é texto plano, legível e está neste repositório — leia antes de compilar.
- O `Build-HWuP.bat` compila **localmente, na sua máquina**, a partir do código que você mesmo baixou — você não está rodando um binário de origem desconhecida.
- Compare o hash do `.exe` gerado com o que está na seção de Releases, se quiser uma checagem extra.

### Requisitos

Windows 10/11, PowerShell 5.1 (já vem no Windows), privilégios de administrador (o launcher pede elevação sozinho).

### Como usar

1. Baixe `HWuP.ps1`, `hwup.ico`, `Run-HWuP.bat`, `Build-HWuP.bat` e `Build-HWuP.ps1` — todos na mesma pasta.
2. Pra testar sem compilar: duplo clique em `Run-HWuP.bat`.
3. Pra gerar o `HWuP.exe`: duplo clique em `Build-HWuP.bat` (instala o PS2EXE na primeira vez, com sua autorização).

### Autor

**Júlio Cezar Abreu** — Founder, HWuP PC Enthusiast
Canal no YouTube: https://www.youtube.com/HwupTech
Comunidade com mais de 10 anos de fórum ativo em hardware e tuning de PC.

### Licença

MIT — use, modifique e redistribua, mantendo os créditos.

---

## 🇺🇸 English

### What it is, in one sentence

A program with a "enter test mode" button and a "go back to normal" button for the Windows protections that get in the way of unsigned drivers, custom kernels, and overclocking tools — and that never lets you forget to turn everything back on afterward.

If you've ever had to manually disable driver signing or Memory Integrity to run some tool, and got annoyed having to remember to flip it back by hand every time: that's exactly what HWuP solves.

### Features

- **Real diagnostics**, read straight from the system: Test Signing, DSE (explained, not read from a single flag), VBS, HVCI/Core Isolation, Credential Guard, Microsoft Defender, per-profile Firewall, Secure Boot (flagged as firmware-dependent), pending reboot, Hyper-V/WSL/Virtual Machine Platform.
- **Enter Test Mode**: shows the exact change plan before applying it, asks for confirmation, applies, verifies every item, prompts for restart with a cancelable countdown.
- **Restore Protected Mode**: only touches what's actually out of the protected profile — reads the state first, never fires commands blind.
- **Reminders and auto-restore**: pick a 1h/2h/3h reminder, or schedule an automatic return via Windows Task Scheduler. Nothing is removed on its own — only manually, via the Reminders button.
- **Optional network control during test mode**: disables only the adapters you pick, with a reactivate button always visible while anything is off.
- **Report export** in TXT and JSON with the full diagnostic and session log.
- **State monitor**: usable for diagnostics alone, without ever entering test mode — a day-to-day Windows security status panel.

### Use cases

- Development and testing of unsigned Windows drivers (WDK, kernel debugging).
- Overclocking and tuning tools that rely on a custom kernel or injector — e.g. **mVolt+** for voltage/clock unlocking on RTX 50-series GPUs, and similar tools that need an unsigned driver loaded.
- Testing inside a VM or isolated environment with hypervisor/code integrity set a specific way.
- Educational security research and reverse engineering, in a controlled environment.
- Day-to-day monitoring of Windows' security state, without ever leaving protected mode.

### Responsible use

HWuP deliberately reduces Windows protections when you ask it to, to enable legitimate development, overclocking, and testing. It is **not** built for piracy, for bypassing anti-cheat, DRM, or any third-party game/software protection, nor for violating platform terms of service. HWuP does not support or endorse illegal use, piracy, or bypassing game protections under any circumstance — even knowing this kind of environment is also used by others for that purpose, that has never been and will never be this project's goal.

HWuP never disables Microsoft Defender, Firewall, or Secure Boot — in any mode.

### Why asking for admin and toggling protections isn't a red flag

**In plain terms**: Windows only lets any program — including Windows' own Settings app — change these protections if it's running as administrator. That's not a special HWuP privilege; it's the same requirement Windows enforces for anyone touching these settings, whether through HWuP, Command Prompt, or the Windows Security screen.

**In technical terms**: everything HWuP does is expose, through a UI with confirmation and logging, commands Microsoft itself documents and officially provides:

- `bcdedit /set testsigning on|off` is Microsoft's official mechanism for toggling driver test-signing mode, documented at [learn.microsoft.com/windows-hardware/drivers/install/the-testsigning-boot-configuration-option](https://learn.microsoft.com/windows-hardware/drivers/install/the-testsigning-boot-configuration-option).
- Turning Memory Integrity (HVCI) and Virtual Machine Platform off and back on **is a feature Microsoft itself supports and recommends for gamers**, documented officially at [support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613](https://support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613) — Microsoft literally writes: *"Gamers who want to prioritize performance have the option to turn off these features while gaming and turn them back on when finished."* HWuP automates exactly that cycle, with verification that re-enabling actually happened.
- Compilation uses **PS2EXE**, Markus Scholtes' open-source PowerShell-to-EXE compiler, public source at [github.com/MScholtes/PS2EXE](https://github.com/MScholtes/PS2EXE).

**Honest note on antivirus false positives**: executables produced by PS2EXE (and similar tools) are frequently flagged by heuristic antivirus engines — not because the code is malicious, but because packaging a script into an `.exe` is also a technique malware uses, and heuristics generalize broadly. This is publicly acknowledged by PS2EXE's own maintainer. Because of that:

- The source (`HWuP.ps1`) is plain, readable text in this repository — read it before compiling.
- `Build-HWuP.bat` compiles **locally, on your own machine**, from the code you downloaded yourself — you're not running a binary from an unknown origin.
- Compare the hash of the generated `.exe` against the one in Releases if you want an extra check.

### Requirements

Windows 10/11, PowerShell 5.1 (built into Windows), administrator privileges (the launcher self-elevates).

### How to use

1. Download `HWuP.ps1`, `hwup.ico`, `Run-HWuP.bat`, `Build-HWuP.bat`, and `Build-HWuP.ps1` — all in the same folder.
2. To test without compiling: double-click `Run-HWuP.bat`.
3. To generate `HWuP.exe`: double-click `Build-HWuP.bat` (installs PS2EXE on first run, with your authorization).

### Author

**Júlio Cezar Abreu** — Founder, HWuP PC Enthusiast
YouTube channel: https://www.youtube.com/HwupTech
A community with over 10 years of active hardware/tuning forum history.

### License

MIT — use, modify, and redistribute, keeping credit.

---

### Fontes / Sources

- https://learn.microsoft.com/windows-hardware/drivers/install/the-testsigning-boot-configuration-option
- https://learn.microsoft.com/windows-hardware/drivers/install/test-signing
- https://support.microsoft.com/article/a255f612-2949-4373-a566-ff6f3f474613
- https://github.com/MScholtes/PS2EXE
