# Isaac Pack ES · instalador para Windows 10 y 11
# Hace: localiza Isaac en Steam, instala lo que NO es de Workshop (lanzador de REPENTOGON, mod de traducción y panel
# del juego), te dice qué mods de Workshop faltan y te ayuda a suscribirte, aplica la corrección de Job y activa los
# packs que elijas (o los que hayas guardado en el panel del juego).
# Se puede ejecutar varias veces: cada vez comprueba el estado real.
#   -Rapido  no pregunta nada: aplica lo guardado en el panel (o tu última elección) y refresca el panel.
# Contacto: https://www.instagram.com/_shun._05/
param([string]$Juego, [switch]$Rapido)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Raiz = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Version = '1.3'
$Estado = Join-Path $env:LOCALAPPDATA 'IsaacPackES'
New-Item -ItemType Directory -Path $Estado -Force | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)   # sin BOM: un BOM al inicio rompe los .lua

$Packs = [ordered]@{
    base        = 'Base (siempre activo)'
    qol         = 'Calidad de vida'
    interfaz    = 'Interfaz e información'
    rendimiento = 'Rendimiento y estabilidad'
    sinergias   = 'Sinergias y jugabilidad'
    contenido   = 'Contenido grande (expansiones)'
    personajes  = 'Personajes'
    visual      = 'Visual y audio'
    capricho    = 'Caprichos'
    trucos      = 'Trucos y herramientas'
}
$Presets = @{
    '1' = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'visual')                                                      # clean
    '2' = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'contenido', 'personajes', 'visual', 'capricho', 'trucos')     # completo
    '3' = @('base', 'qol', 'interfaz', 'rendimiento')                                                                              # mínimo
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
function Lua-Str($s) { '"' + ([string]$s).Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n') + '"' }

# Selección guardada desde el panel del juego (data\isaac_pack_panel\save*.dat), si es más nueva que la última aplicada.
function Leer-Pendiente($juego) {
    $c = Join-Path $juego 'data\isaac_pack_panel'
    if (-not (Test-Path $c)) { return $null }
    $f = Get-ChildItem $c -Filter 'save*.dat' -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (-not $f) { return $null }
    $marca = Join-Path $Estado 'panel_aplicado.txt'
    if ((Test-Path $marca) -and ($f.LastWriteTimeUtc.Ticks -le [int64](Get-Content $marca -Raw))) { return $null }
    try { $j = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch { return $null }
    $j | Add-Member -NotePropertyName ticks -NotePropertyValue $f.LastWriteTimeUtc.Ticks -Force
    return $j
}

# Copia corregida de Job 2.5: su main.lua hace require() dentro de un callback y falla («module job_src.mod_compat.others not found»).
function Parche-Job($modsDir, $juego) {
    $orig = Get-ChildItem $modsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '_2567634705$' } | Select-Object -First 1
    if (-not $orig) { return }
    $dest = Join-Path $modsDir 'job_corregido'
    $mainTxt = [IO.File]::ReadAllText((Join-Path $orig.FullName 'main.lua'))
    $viejo = 'require("job_src.mod_compat.others")'
    if (-not $mainTxt.Contains($viejo)) { Aviso 'Job: el main.lua ya no tiene la línea esperada; revisa el parche a mano.'; return }
    $huella = (Get-FileHash (Join-Path $orig.FullName 'main.lua') -Algorithm SHA256).Hash
    $marca = Join-Path $dest '.origen_sha'
    if (-not ((Test-Path $marca) -and ((Get-Content $marca -Raw).Trim() -eq $huella))) {
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        New-Item -ItemType Directory -Path $dest | Out-Null
        Copy-Item (Join-Path $orig.FullName '*') $dest -Recurse -Force -Exclude 'disable.it'
        [IO.File]::WriteAllText((Join-Path $dest 'main.lua'), $mainTxt.Replace($viejo, 'pcall(require, "job_src.mod_compat.others")'), $utf8)
        $meta = [IO.File]::ReadAllText((Join-Path $dest 'metadata.xml'))
        $meta = [regex]::Replace($meta, '<name>.*?</name>', '<name>Job (corregido)</name>', 'Singleline')
        $meta = [regex]::Replace($meta, '<directory>.*?</directory>', '<directory>job_corregido</directory>', 'Singleline')
        $meta = [regex]::Replace($meta, '\s*<id>.*?</id>', '', 'Singleline')
        [IO.File]::WriteAllText((Join-Path $dest 'metadata.xml'), $meta, $utf8)
        [IO.File]::WriteAllText($marca, $huella, $utf8)
        $datosJob = Join-Path $juego 'data\job'
        if ((Test-Path $datosJob) -and -not (Test-Path (Join-Path $juego 'data\job_corregido'))) { Copy-Item $datosJob (Join-Path $juego 'data\job_corregido') -Recurse }
        Ok 'Job: copia corregida creada (mods\job_corregido).'
    }
    Poner-Marca $orig.FullName      # el original se apaga: los dos a la vez duplicarían objetos
    Quitar-Marca $dest
}

# Errores Lua del log de la sesión anterior, agrupados por mod.
function Errores-Sesion {
    $log = Join-Path $env:USERPROFILE 'Documents\My Games\Binding of Isaac Repentance+\log.txt'
    $res = [ordered]@{}
    if (-not (Test-Path $log)) { return @() }
    $lineas = [IO.File]::ReadAllLines($log)
    for ($i = 0; $i -lt $lineas.Length; $i++) {
        $m = [regex]::Match($lineas[$i], 'Error in "([^"]+)" call from "([^"]+)": (.*)')
        if (-not $m.Success) { continue }
        $mod = $m.Groups[2].Value
        if (-not $res.Contains($mod)) {
            $pila = @()
            for ($j = $i + 1; $j -lt [Math]::Min($i + 14, $lineas.Length); $j++) {
                if ([string]::IsNullOrWhiteSpace($lineas[$j]) -or $lineas[$j].StartsWith('[INFO]')) { break }
                $pila += $lineas[$j].Trim()
            }
            $msg = ($m.Groups[1].Value + ': ' + $m.Groups[3].Value)
            $res[$mod] = @{ mod = $mod; n = 0; msg = $msg.Substring(0, [Math]::Min(400, $msg.Length)); pila = ($pila -join "`n") }
        }
        $res[$mod].n++
    }
    return @($res.Values | Sort-Object { -$_.n })
}

# Genera mods\isaac_pack_panel\panel_datos.lua con el estado real (mismo formato que el de Mac).
function Escribir-Panel($modsDir, $mods, $instalados, $elegidos) {
    $dest = Join-Path $modsDir 'isaac_pack_panel'
    if (-not (Test-Path $dest)) { return }
    $activo = @{}
    foreach ($m in $mods) {
        $activo[$m.id] = $false
        if ($instalados.ContainsKey($m.id) -and -not $instalados[$m.id].StartsWith($script:WorkshopDir, [StringComparison]::OrdinalIgnoreCase)) {
            $activo[$m.id] = -not (Test-Path (Join-Path $instalados[$m.id] 'disable.it'))
        }
    }
    $L = New-Object Collections.Generic.List[string]
    $L.Add('return { version = ' + (Lua-Str $Version) + ', generado = ' + (Lua-Str (Get-Date -Format 'yyyy-MM-dd HH:mm')) + ',')
    $L.Add('packs = {')
    $sel = @()
    foreach ($k in $Packs.Keys) {
        if ($k -eq 'base') { continue }
        $g = @($mods | Where-Object { $_.pack -eq $k -and $instalados.ContainsKey($_.id) })
        $enc = @($g | Where-Object { -not $_.apagado })
        $act = @($g | Where-Object { $activo[$_.id] }).Count
        $tot = @($mods | Where-Object { $_.pack -eq $k }).Count
        if ($enc.Count -gt 0 -and (@($enc | Where-Object { -not $activo[$_.id] }).Count -eq 0)) { $sel += $k }
        $L.Add('{ k = ' + (Lua-Str $k) + ', n = ' + (Lua-Str $Packs[$k]) + ', d = "", activos = ' + $act + ', total = ' + $tot + ' },')
    }
    $L.Add('},')
    $pre = @()
    foreach ($n in @(@('clean', '1'), @('completo', '2'), @('minimo', '3'))) {
        $pre += ($n[0] + ' = { ' + ((@($Presets[$n[1]] | Where-Object { $_ -ne 'base' }) | ForEach-Object { Lua-Str $_ }) -join ', ') + ' }')
    }
    $L.Add('presets = { ' + ($pre -join ', ') + ' },')
    $L.Add('seleccion = { ' + (($sel | ForEach-Object { "$_ = true" }) -join ', ') + ' },')
    $L.Add('mods = {')
    $orden = @($Packs.Keys)
    foreach ($m in ($mods | Sort-Object @{ Expression = { $orden.IndexOf($_.pack) } }, @{ Expression = { $_.nombre.ToLower() } })) {
        if ($m.pack -eq 'descartado') { continue }
        $pn = if ($Packs.Contains($m.pack)) { $Packs[$m.pack] } else { $m.pack }
        $rg = if ($m.rgon) { $m.rgon } else { 'no' }
        $d = [string]$m.descripcion; if ($d.Length -gt 200) { $d = $d.Substring(0, 200) }
        $L.Add('{ id = ' + (Lua-Str $m.id) + ', n = ' + (Lua-Str $m.nombre) + ', p = ' + (Lua-Str $m.pack) + ', pn = ' + (Lua-Str $pn) + ', v = ' + (Lua-Str $m.veredicto) +
            ', i = ' + $(if ($instalados.ContainsKey($m.id)) { 'true' } else { 'false' }) + ', a = ' + $(if ($activo[$m.id]) { 'true' } else { 'false' }) +
            ', ap = ' + $(if ($m.apagado) { 'true' } else { 'false' }) + ', rg = ' + (Lua-Str $rg) + ', d = ' + (Lua-Str $d) + ' },')
    }
    $L.Add('},')
    $L.Add('errores = {')
    foreach ($e in (Errores-Sesion | Select-Object -First 30)) {
        $L.Add('{ mod = ' + (Lua-Str $e.mod) + ', n = ' + $e.n + ', msg = ' + (Lua-Str $e.msg) + ', pila = ' + (Lua-Str $e.pila) + ' },')
    }
    $L.Add('}, }')
    [IO.File]::WriteAllText((Join-Path $dest 'panel_datos.lua'), (($L -join "`n") + "`n"), $utf8)
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
if (Get-Process -Name 'isaac-ng' -ErrorAction SilentlyContinue) { throw 'Isaac está abierto. Ciérralo del todo y vuelve a ejecutar.' }
Ok $Juego
$ModsDir = Join-Path $Juego 'mods'
$script:WorkshopDir = Join-Path (Split-Path (Split-Path $Juego)) 'workshop\content\250900'
if (-not (Test-Path $ModsDir)) { New-Item -ItemType Directory -Path $ModsDir | Out-Null }

$datos = Get-Content (Join-Path $Raiz 'datos\mods.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$mods = @($datos.mods)

# ---------------------------------------------------------------- 2. Packs
Titulo '2. ¿Qué quieres jugar?'
$pend = Leer-Pendiente $Juego
$on = @(); $off = @()
if ($pend) {
    $elegidos = @('base') + @($pend.packs | Where-Object { $Packs.Contains($_) -and $_ -ne 'base' })
    $on = @($pend.on | ForEach-Object { "$_" }); $off = @($pend.off | ForEach-Object { "$_" })
    Ok ('Usando la selección guardada en el panel del juego: ' + (($elegidos | ForEach-Object { $Packs[$_] }) -join ', '))
} elseif ($Rapido -and (Test-Path (Join-Path $Estado 'ultimo.txt'))) {
    $elegidos = @((Get-Content (Join-Path $Estado 'ultimo.txt') -Raw).Trim() -split ',')
    Ok ('Repitiendo tu última elección: ' + (($elegidos | ForEach-Object { $Packs[$_] }) -join ', '))
} else {
    Write-Host '   1) Clean (recomendado): calidad de vida, interfaz, rendimiento, sinergias y visual'
    Write-Host '   2) Completo: todo, también expansiones grandes, caprichos y trucos (puede dar choques)'
    Write-Host '   3) Mínimo: solo calidad de vida, interfaz y rendimiento'
    $op = Read-Host '   Elige 1, 2 o 3 [1]'
    if (-not $Presets.ContainsKey($op)) { $op = '1' }
    $elegidos = $Presets[$op]
    Ok ('Packs: ' + (($elegidos | ForEach-Object { $Packs[$_] }) -join ', '))
}
Set-Content (Join-Path $Estado 'ultimo.txt') ($elegidos -join ',')
function Debe-Estar-Activo($m) {
    if ($on -contains $m.id) { return $true }
    if ($off -contains $m.id) { return $false }
    return (($elegidos -contains $m.pack) -and $m.pack -ne 'descartado' -and -not $m.apagado)
}

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
    Ok "Acceso directo creado en el Escritorio: «Isaac con REPENTOGON». Abre Isaac SIEMPRE desde ahí (con Steam abierto)."
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
if (Test-Path $script:WorkshopDir) { foreach ($d in (Get-ChildItem $script:WorkshopDir -Directory)) { if (-not $instalados.ContainsKey($d.Name)) { $instalados[$d.Name] = $d.FullName } } }
$necesarios = @($mods | Where-Object { (Debe-Estar-Activo $_) -and -not $_.no_suscribir })
$faltan = @($necesarios | Where-Object { -not $instalados.ContainsKey($_.id) })
Ok "$($necesarios.Count - $faltan.Count) de $($necesarios.Count) mods de tu selección ya están descargados."
if ($faltan.Count -gt 0 -and -not $Rapido) {
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
} elseif ($faltan.Count -gt 0) {
    Aviso "Faltan $($faltan.Count) mods por suscribir: ejecuta el instalador normal (sin -Rapido) para suscribirte."
}

# ---------------------------------------------------------------- 5. Packs, parches y panel
Titulo '5. Activando tus packs'
Parche-Job $ModsDir $Juego
$aplicados = 0
foreach ($m in $mods) {
    if (-not $instalados.ContainsKey($m.id)) { continue }
    $carpeta = $instalados[$m.id]
    if ($carpeta.StartsWith($script:WorkshopDir, [StringComparison]::OrdinalIgnoreCase)) { continue }   # aún no copiado a mods\: se aplica en la próxima ejecución
    if ($m.id -eq '2567634705') { continue }   # Job original: lo gestiona Parche-Job (queda apagado a favor de «Job (corregido)»)
    if (Debe-Estar-Activo $m) { Quitar-Marca $carpeta } else { Poner-Marca $carpeta }
    $aplicados++
}
if ($pend) { Set-Content (Join-Path $Estado 'panel_aplicado.txt') ([string]$pend.ticks) }
Escribir-Panel $ModsDir $mods $instalados $elegidos
Ok "$aplicados mods configurados y panel del juego actualizado."
Aviso 'Los mods recién descargados aparecen en la carpeta mods al abrir Isaac por primera vez. Cuando termine de cargar, cierra el juego y VUELVE A EJECUTAR este instalador (o Aplicar_seleccion.bat) para activar solo tus packs.'

# ---------------------------------------------------------------- 6. Idioma y panel
Titulo '6. Español y panel'
Write-Host '   Steam > Biblioteca > The Binding of Isaac > Propiedades > Idioma > Español.'
Write-Host '   Dentro del juego, con REPENTOGON: pulsa ~ y abre «Packs ES», o pulsa F9, para elegir packs y mods.'
Write-Host '   Después de guardar en el panel, cierra Isaac y ejecuta Aplicar_seleccion.bat.'
Write-Host ''
Write-Host '   Listo. Abre Isaac con «Isaac con REPENTOGON» (Escritorio).' -ForegroundColor Green
