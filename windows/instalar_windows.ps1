# Isaac Pack ES · instalador para Windows 10 y 11
# Hace: localiza Isaac en Steam, instala lo que NO es de Workshop (lanzador de REPENTOGON y el mod de
# traducción), te dice qué mods de Workshop faltan y te ayuda a suscribirte, y activa los packs que elijas.
# Se puede ejecutar varias veces: cada vez comprueba el estado real. Contacto: https://www.instagram.com/_shun._05/
param([string]$Juego)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Raiz = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Version = '0.8'

$Packs = [ordered]@{
    base       = 'Base (siempre activo)'
    qol        = 'Calidad de vida'
    interfaz   = 'Interfaz e información'
    rendimiento = 'Rendimiento y estabilidad'
    sinergias  = 'Sinergias y jugabilidad'
    contenido  = 'Contenido grande (expansiones)'
    personajes = 'Personajes'
    visual     = 'Visual y audio'
    capricho   = 'Caprichos'
    trucos     = 'Trucos y herramientas'
}
$Presets = @{
    '1' = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'visual')                                   # clean
    '2' = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'contenido', 'personajes', 'visual', 'capricho', 'trucos')  # completo
    '3' = @('base', 'qol', 'interfaz', 'rendimiento')                                                           # mínimo
}

function Titulo($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "   [OK] $t" -ForegroundColor Green }
function Aviso($t)  { Write-Host "   [!]  $t" -ForegroundColor Yellow }

function Buscar-Juego {
    $libs = @()
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if ($steam) {
        $steam = $steam -replace '/', '\'
        $libs += $steam
        $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($m in [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs += ($m.Groups[1].Value -replace '\\\\', '\')
            }
        }
    }
    foreach ($l in ($libs | Select-Object -Unique)) {
        $d = Join-Path $l 'steamapps\common\The Binding of Isaac Rebirth'
        if (Test-Path (Join-Path $d 'isaac-ng.exe')) { return $d }
    }
    return $null
}

function Quitar-Marca($carpeta) {
    $m = Join-Path $carpeta 'disable.it'
    if (Test-Path $m) { Remove-Item $m -Force }
}
function Poner-Marca($carpeta) {
    $m = Join-Path $carpeta 'disable.it'
    $item = Get-Item $m -Force -ErrorAction SilentlyContinue
    if ($item -and $item.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-Item $m -Force; $item = $null }  # nunca seguir enlaces
    if (-not $item) { New-Item -ItemType File -Path $m -Force | Out-Null }
}

Write-Host ''
Write-Host "  Isaac Pack ES v$Version · instalador para Windows" -ForegroundColor White
Write-Host '  The Binding of Isaac: Repentance+ · mods en español' -ForegroundColor DarkGray

# ---------------------------------------------------------------- 1. Juego
Titulo '1. Buscando Isaac en Steam'
if (-not $Juego) { $Juego = Buscar-Juego }
if (-not $Juego) {
    Aviso 'No encuentro Isaac automáticamente.'
    $Juego = Read-Host '   Pega la ruta de la carpeta del juego (donde está isaac-ng.exe)'
}
if (-not (Test-Path (Join-Path $Juego 'isaac-ng.exe'))) { throw "No hay isaac-ng.exe en '$Juego'. Instala Isaac desde Steam y vuelve a ejecutar." }
Ok $Juego
$ModsDir = Join-Path $Juego 'mods'
$WorkshopDir = Join-Path (Split-Path (Split-Path $Juego)) 'workshop\content\250900'
if (-not (Test-Path $ModsDir)) { New-Item -ItemType Directory -Path $ModsDir | Out-Null }

$datos = Get-Content (Join-Path $Raiz 'datos\mods.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$mods = @($datos.mods)

# ---------------------------------------------------------------- 2. Packs
Titulo '2. ¿Qué quieres jugar?'
Write-Host '   1) Clean (recomendado): calidad de vida, interfaz, rendimiento, sinergias y visual'
Write-Host '   2) Completo: todo, también expansiones grandes, caprichos y trucos (puede dar choques)'
Write-Host '   3) Mínimo: solo calidad de vida, interfaz y rendimiento'
$op = Read-Host '   Elige 1, 2 o 3 [1]'
if (-not $Presets.ContainsKey($op)) { $op = '1' }
$elegidos = $Presets[$op]
Ok ('Packs: ' + (($elegidos | ForEach-Object { $Packs[$_] }) -join ', '))

# ---------------------------------------------------------------- 3. Lo que NO es de Workshop
Titulo '3. Instalando lo que no es de Workshop'
$lanz = Join-Path $Juego 'REPENTOGONLauncher'
if (Test-Path (Join-Path $lanz 'REPENTOGONLauncher.exe')) {
    Ok 'Lanzador de REPENTOGON ya instalado (se actualiza solo).'
} else {
    $h = @{ 'User-Agent' = 'IsaacPackES' }
    $rel = Invoke-RestMethod 'https://api.github.com/repos/TeamREPENTOGON/Launcher/releases/latest' -Headers $h
    $zipA = $rel.assets | Where-Object { $_.name -eq 'REPENTOGONLauncher.zip' } | Select-Object -First 1
    $hashA = $rel.assets | Where-Object { $_.name -eq 'hash.txt' } | Select-Object -First 1
    if (-not $zipA -or -not $hashA) { throw 'La release del lanzador no tiene el formato esperado.' }
    $tmp = Join-Path $env:TEMP 'REPENTOGONLauncher.zip'
    Invoke-WebRequest $zipA.browser_download_url -OutFile $tmp -UseBasicParsing
    $c = (Invoke-WebRequest $hashA.browser_download_url -UseBasicParsing).Content
    if ($c -is [byte[]]) { $c = [Text.Encoding]::UTF8.GetString($c) }
    $esperado = ([string]$c).Trim().ToLower()
    $real = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
    if ($real -ne $esperado) { Remove-Item $tmp -Force; throw 'El lanzador descargado no coincide con su hash oficial: no se instala.' }
    New-Item -ItemType Directory -Path $lanz -Force | Out-Null
    Expand-Archive $tmp -DestinationPath $lanz -Force
    Remove-Item $tmp -Force
    Ok "Lanzador de REPENTOGON $($rel.tag_name) instalado (hash oficial verificado)."
}
$escritorio = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $escritorio 'Isaac con REPENTOGON.lnk'
if (-not (Test-Path $lnk)) {
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($lnk)
    $s.TargetPath = Join-Path $lanz 'REPENTOGONLauncher.exe'
    $s.WorkingDirectory = $lanz
    $s.Save()
    Ok "Acceso directo creado en el Escritorio: «Isaac con REPENTOGON». Abre Isaac SIEMPRE desde ahí."
}
$local = Join-Path $Raiz 'mods_locales'
if (Test-Path $local) {
    foreach ($d in Get-ChildItem $local -Directory) {
        $dest = Join-Path $ModsDir $d.Name
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item (Join-Path $d.FullName '*') $dest -Recurse -Force
        Ok "Mod local instalado: $($d.Name)"
    }
}

# ---------------------------------------------------------------- 4. Mods de Workshop
Titulo '4. Mods de Workshop'
$instalados = @{}
foreach ($d in (Get-ChildItem $ModsDir -Directory -ErrorAction SilentlyContinue)) { if ($d.Name -match '_(\d+)$') { $instalados[$Matches[1]] = $d.FullName } }
if (Test-Path $WorkshopDir) { foreach ($d in (Get-ChildItem $WorkshopDir -Directory)) { if (-not $instalados.ContainsKey($d.Name)) { $instalados[$d.Name] = $d.FullName } } }
$necesarios = @($mods | Where-Object { $elegidos -contains $_.pack -and $_.pack -ne 'descartado' -and -not $_.no_suscribir })
$faltan = @($necesarios | Where-Object { -not $instalados.ContainsKey($_.id) })
Ok "$($necesarios.Count - $faltan.Count) de $($necesarios.Count) mods de tus packs ya están descargados."
if ($faltan.Count -gt 0) {
    Aviso "Faltan $($faltan.Count) mods de Workshop:"
    $faltan | ForEach-Object { Write-Host "       - $($_.nombre)" }
    Write-Host ''
    Write-Host '   Steam solo deja suscribirse con tu sesión. Elige cómo:'
    Write-Host '   1) Suscribirme a todos de golpe (copio un script; lo pegas en steamcommunity.com)'
    Write-Host '   2) Abrir la página de cada mod en la aplicación de Steam (clic en Suscribirse)'
    Write-Host '   3) Nada ahora'
    $o = Read-Host '   Elige 1, 2 o 3 [1]'
    if ($o -eq '2') {
        foreach ($m in $faltan) { Start-Process "steam://url/CommunityFilePage/$($m.id)"; Start-Sleep -Seconds 3 }
        Aviso 'Se han abierto en Steam. Pulsa «Suscribirse» en cada una.'
    } elseif ($o -ne '3') {
        $ids = ($faltan | ForEach-Object { "'$($_.id)'" }) -join ','
        $js = "(async()=>{for(const id of [$ids]){const r=await fetch('/sharedfiles/subscribe',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({id,appid:'250900',sessionid:g_sessionID})});console.log(id,r.status);await new Promise(o=>setTimeout(o,800));}console.log('Hecho. Abre Steam y espera a que descargue.');})();"
        Set-Clipboard -Value $js
        Start-Process 'https://steamcommunity.com/my/'
        Write-Host ''
        Write-Host '   Hecho: el script está COPIADO al portapapeles. Ahora:'
        Write-Host '     1. En la página que se abre, inicia sesión en Steam si no lo estás.'
        Write-Host '     2. Pulsa F12, ve a la pestaña «Consola», pega con Ctrl+V y pulsa Intro.'
        Write-Host '     3. Abre Steam y espera a que termine de descargar.'
    }
}

# ---------------------------------------------------------------- 5. Packs
Titulo '5. Activando tus packs'
$aplicados = 0
foreach ($m in $mods) {
    if (-not $instalados.ContainsKey($m.id)) { continue }
    $carpeta = $instalados[$m.id]
    if ($carpeta.StartsWith($WorkshopDir, [StringComparison]::OrdinalIgnoreCase)) { continue }   # aún no copiado a mods/: se aplica en la próxima ejecución
    if (($elegidos -contains $m.pack) -and $m.pack -ne 'descartado' -and -not $m.apagado) { Quitar-Marca $carpeta } else { Poner-Marca $carpeta }
    $aplicados++
}
Ok "$aplicados mods configurados."
Aviso 'Los mods recién descargados aparecen en la carpeta mods al abrir Isaac por primera vez. Cuando termine de cargar, cierra el juego y VUELVE A EJECUTAR este instalador para activar solo tus packs.'

# ---------------------------------------------------------------- 6. Idioma
Titulo '6. Español'
Write-Host '   Steam > Biblioteca > The Binding of Isaac > Propiedades > Idioma > Español.'
Write-Host '   EID mostrará los objetos en español con su ajuste «auto».'
Write-Host ''
Write-Host '   Listo. Abre Isaac con «Isaac con REPENTOGON» (Escritorio).' -ForegroundColor Green
