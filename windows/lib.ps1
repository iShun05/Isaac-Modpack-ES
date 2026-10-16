# Isaac Pack ES · lógica común del instalador de Windows (la usan la ventana y la consola).
# Se carga con «. lib.ps1» después de definir $Raiz (carpeta del paquete) y, si quieres, $script:LogFn.
# Contacto: https://www.instagram.com/_shun._05/

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$script:Raiz = $Raiz
$script:Version = (Get-Content -Path (Join-Path $script:Raiz 'VERSION') -Raw -Encoding UTF8 -ErrorAction Stop).Trim()
$script:Estado = Join-Path $env:LOCALAPPDATA 'IsaacPackES'
New-Item -ItemType Directory -Path $script:Estado -Force | Out-Null
$script:utf8 = New-Object Text.UTF8Encoding($false)   # sin BOM: un BOM al inicio rompe los .lua
$script:LogFn = $null
$script:Tick = $null   # la ventana pone aquí DoEvents para no congelarse mientras espera

$script:Packs = [ordered]@{
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
$script:PackDesc = @{
    qol = 'Arreglos y comodidades que no cambian el equilibrio'
    interfaz = 'HUD, estadísticas, enciclopedia y recordatorios'
    rendimiento = 'Menos tirones y menos cierres con muchos objetos y mods'
    sinergias = 'Sinergias nuevas, objetos extra y pequeños cambios de reglas'
    contenido = 'Expansiones con muchos objetos, enemigos y mecánicas'
    personajes = 'Personajes jugables nuevos'
    visual = 'Sprites, animaciones, música y doblaje'
    capricho = 'Memes, cambios de aspecto y modos de caos'
    trucos = 'Menús de trucos y atajos para probar cosas'
}
$script:Presets = [ordered]@{
    clean    = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'visual')
    completo = @('base', 'qol', 'interfaz', 'rendimiento', 'sinergias', 'contenido', 'personajes', 'visual', 'capricho', 'trucos')
    minimo   = @('base', 'qol', 'interfaz', 'rendimiento')
}

function Log($t, $nivel = 'info') {
    if ($script:LogFn) { & $script:LogFn $t $nivel } else { Write-Host $t }
}

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

# Fija la carpeta del juego y carga el manifiesto. Devuelve $false si no es una instalación válida de Isaac.
function Iniciar-Contexto($juego) {
    if (-not $juego -or -not (Test-Path (Join-Path $juego 'isaac-ng.exe'))) { return $false }
    $script:Juego = $juego
    $script:ModsDir = Join-Path $juego 'mods'
    $script:WorkshopDir = Join-Path (Split-Path (Split-Path $juego)) 'workshop\content\250900'
    if (-not (Test-Path $script:ModsDir)) { New-Item -ItemType Directory -Path $script:ModsDir | Out-Null }
    $datos = Get-Content (Join-Path $script:Raiz 'datos\mods.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $script:Mods = @($datos.mods)
    return $true
}

function Isaac-Abierto { return [bool](Get-Process -Name 'isaac-ng' -ErrorAction SilentlyContinue) }
function Steam-Abierto { return [bool](Get-Process -Name 'steam' -ErrorAction SilentlyContinue) }

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

# ¿Debe estar activo este mod? Una orden suelta (panel o ventana) gana al pack; «apagado» = se activa a mano.
function Debe-Estar-Activo($m, $elegidos, $on, $off) {
    if ($on -contains $m.id) { return $true }
    if ($off -contains $m.id) { return $false }
    return (($elegidos -contains $m.pack) -and $m.pack -ne 'descartado' -and -not $m.apagado)
}

# Mods de Workshop presentes: id -> carpeta (en mods\ o, si Steam aún no los copió, en workshop\content).
function Leer-Instalados {
    $r = @{}
    foreach ($d in (Get-ChildItem $script:ModsDir -Directory -ErrorAction SilentlyContinue)) { if ($d.Name -match '_(\d+)$') { $r[$Matches[1]] = $d.FullName } }
    if (Test-Path $script:WorkshopDir) { foreach ($d in (Get-ChildItem $script:WorkshopDir -Directory)) { if (-not $r.ContainsKey($d.Name)) { $r[$d.Name] = $d.FullName } } }
    $script:Instalados = $r
    return $r
}
function En-Workshop($carpeta) { return $carpeta.StartsWith($script:WorkshopDir, [StringComparison]::OrdinalIgnoreCase) }

# Selección guardada desde el panel del juego (data\isaac_pack_panel\save*.dat), si es más nueva que la última aplicada.
function Leer-Pendiente {
    $c = Join-Path $script:Juego 'data\isaac_pack_panel'
    if (-not (Test-Path $c)) { return $null }
    $f = Get-ChildItem $c -Filter 'save*.dat' -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (-not $f) { return $null }
    $marca = Join-Path $script:Estado 'panel_aplicado.txt'
    if ((Test-Path $marca) -and ($f.LastWriteTimeUtc.Ticks -le [int64](Get-Content $marca -Raw))) { return $null }
    try { $j = Get-Content $f.FullName -Raw | ConvertFrom-Json } catch { return $null }
    $j | Add-Member -NotePropertyName ticks -NotePropertyValue $f.LastWriteTimeUtc.Ticks -Force
    return $j
}

# ---------------------------------------------------------------- Lo que NO es de Workshop
function Instalar-Lanzador {
    $lanz = Join-Path $script:Juego 'REPENTOGONLauncher'
    if (Test-Path (Join-Path $lanz 'REPENTOGONLauncher.exe')) { Log 'Lanzador de REPENTOGON ya instalado (se actualiza solo).' 'ok'; return $true }
    Log 'Descargando el lanzador oficial de REPENTOGON…'
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
    Log "Lanzador de REPENTOGON $($rel.tag_name) instalado (hash oficial verificado)." 'ok'
    return $true
}

function Crear-Acceso {
    $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Isaac con REPENTOGON.lnk'
    if (Test-Path $lnk) { return }
    $lanz = Join-Path $script:Juego 'REPENTOGONLauncher'
    $w = New-Object -ComObject WScript.Shell
    $s = $w.CreateShortcut($lnk)
    $s.TargetPath = Join-Path $lanz 'REPENTOGONLauncher.exe'
    $s.WorkingDirectory = $lanz
    $s.Save()
    Log 'Acceso directo creado en el Escritorio: «Isaac con REPENTOGON».' 'ok'
}

function Ruta-Ini-Lanzador { Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)) 'My Games\repentogon_launcher.ini' }

function Configurar-Ruta-Lanzador {
    $ini = Ruta-Ini-Lanzador
    $carpeta = Split-Path $ini
    if (-not (Test-Path $carpeta)) { New-Item -ItemType Directory -Path $carpeta -Force | Out-Null }
    $linea = 'IsaacExecutable = ' + (Join-Path $script:Juego 'isaac-ng.exe')
    $salto = "`r`n"
    if (Test-Path $ini) {
        $texto = [IO.File]::ReadAllText($ini)
        if ($texto.Contains("`n") -and -not $texto.Contains("`r`n")) { $salto = "`n" }
        $reemplazo = $linea.Replace('$', '$$')
        if ([regex]::IsMatch($texto, '(?im)^\s*IsaacExecutable\s*=.*$')) {
            $texto = [regex]::Replace($texto, '(?im)^\s*IsaacExecutable\s*=.*$', $reemplazo, 1)
        } elseif ([regex]::IsMatch($texto, '(?im)^\s*\[General\]\s*$')) {
            $texto = [regex]::Replace($texto, '(?im)^\s*\[General\]\s*$', ('$0' + $salto + $reemplazo), 1)
        } else {
            $texto = $texto.TrimEnd("`r", "`n") + $salto + '[General]' + $salto + $linea + $salto
        }
    } else {
        $texto = '[General]' + $salto + $linea + $salto
    }
    [IO.File]::WriteAllText($ini, $texto, (New-Object Text.UTF8Encoding($false)))
    return $ini
}

function Instalar-Locales {
    $local = Join-Path $script:Raiz 'mods_locales'
    if (-not (Test-Path $local)) { return }
    foreach ($d in Get-ChildItem $local -Directory) {
        $dest = Join-Path $script:ModsDir $d.Name
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item (Join-Path $d.FullName '*') $dest -Recurse -Force
        Log "Mod local instalado: $($d.Name)" 'ok'
    }
}

# Copia corregida de Job 2.5: su main.lua hace require() dentro de un callback y falla («module job_src.mod_compat.others not found»).
function Parche-Job {
    $orig = Get-ChildItem $script:ModsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '_2567634705$' } | Select-Object -First 1
    if (-not $orig) { return }
    $dest = Join-Path $script:ModsDir 'job_corregido'
    $mainTxt = [IO.File]::ReadAllText((Join-Path $orig.FullName 'main.lua'))
    $viejo = 'require("job_src.mod_compat.others")'
    if (-not $mainTxt.Contains($viejo)) { Log 'Job: el main.lua ya no tiene la línea esperada; revisa el parche a mano.' 'aviso'; return }
    $huella = (Get-FileHash (Join-Path $orig.FullName 'main.lua') -Algorithm SHA256).Hash
    $marca = Join-Path $dest '.origen_sha'
    if (-not ((Test-Path $marca) -and ((Get-Content $marca -Raw).Trim() -eq $huella))) {
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        New-Item -ItemType Directory -Path $dest | Out-Null
        Copy-Item (Join-Path $orig.FullName '*') $dest -Recurse -Force -Exclude 'disable.it'
        [IO.File]::WriteAllText((Join-Path $dest 'main.lua'), $mainTxt.Replace($viejo, 'pcall(require, "job_src.mod_compat.others")'), $script:utf8)
        $meta = [IO.File]::ReadAllText((Join-Path $dest 'metadata.xml'))
        $meta = [regex]::Replace($meta, '<name>.*?</name>', '<name>Job (corregido)</name>', 'Singleline')
        $meta = [regex]::Replace($meta, '<directory>.*?</directory>', '<directory>job_corregido</directory>', 'Singleline')
        $meta = [regex]::Replace($meta, '\s*<id>.*?</id>', '', 'Singleline')
        [IO.File]::WriteAllText((Join-Path $dest 'metadata.xml'), $meta, $script:utf8)
        [IO.File]::WriteAllText($marca, $huella, $script:utf8)
        $datosJob = Join-Path $script:Juego 'data\job'
        if ((Test-Path $datosJob) -and -not (Test-Path (Join-Path $script:Juego 'data\job_corregido'))) { Copy-Item $datosJob (Join-Path $script:Juego 'data\job_corregido') -Recurse }
        Log 'Job: copia corregida creada (mods\job_corregido).' 'ok'
    }
    Poner-Marca $orig.FullName      # el original se apaga: los dos a la vez duplicarían objetos
    Quitar-Marca $dest
}

# ---------------------------------------------------------------- Panel y errores
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
function Escribir-Panel($elegidos) {
    $dest = Join-Path $script:ModsDir 'isaac_pack_panel'
    if (-not (Test-Path $dest)) { return }
    $mods = $script:Mods; $inst = $script:Instalados
    $activo = @{}
    foreach ($m in $mods) {
        $activo[$m.id] = $false
        if ($inst.ContainsKey($m.id) -and -not (En-Workshop $inst[$m.id])) { $activo[$m.id] = -not (Test-Path (Join-Path $inst[$m.id] 'disable.it')) }
    }
    $L = New-Object Collections.Generic.List[string]
    $L.Add('return { version = ' + (Lua-Str $script:Version) + ', generado = ' + (Lua-Str (Get-Date -Format 'yyyy-MM-dd HH:mm')) + ',')
    $L.Add('packs = {')
    $sel = @()
    foreach ($k in $script:Packs.Keys) {
        if ($k -eq 'base') { continue }
        $g = @($mods | Where-Object { $_.pack -eq $k -and $inst.ContainsKey($_.id) })
        $enc = @($g | Where-Object { -not $_.apagado })
        $act = @($g | Where-Object { $activo[$_.id] }).Count
        $tot = @($mods | Where-Object { $_.pack -eq $k }).Count
        if ($enc.Count -gt 0 -and (@($enc | Where-Object { -not $activo[$_.id] }).Count -eq 0)) { $sel += $k }
        $L.Add('{ k = ' + (Lua-Str $k) + ', n = ' + (Lua-Str $script:Packs[$k]) + ', d = ' + (Lua-Str $script:PackDesc[$k]) + ', activos = ' + $act + ', total = ' + $tot + ' },')
    }
    $L.Add('},')
    $pre = @()
    foreach ($n in $script:Presets.Keys) {
        $pre += ($n + ' = { ' + ((@($script:Presets[$n] | Where-Object { $_ -ne 'base' }) | ForEach-Object { Lua-Str $_ }) -join ', ') + ' }')
    }
    $L.Add('presets = { ' + ($pre -join ', ') + ' },')
    $L.Add('seleccion = { ' + (($sel | ForEach-Object { "$_ = true" }) -join ', ') + ' },')
    $L.Add('mods = {')
    $orden = @($script:Packs.Keys)
    foreach ($m in ($mods | Sort-Object @{ Expression = { $orden.IndexOf($_.pack) } }, @{ Expression = { $_.nombre.ToLower() } })) {
        if ($m.pack -eq 'descartado') { continue }
        $pn = if ($script:Packs.Contains($m.pack)) { $script:Packs[$m.pack] } else { $m.pack }
        $rg = if ($m.rgon) { $m.rgon } else { 'no' }
        $d = [string]$m.descripcion; if ($d.Length -gt 200) { $d = $d.Substring(0, 200) }
        $L.Add('{ id = ' + (Lua-Str $m.id) + ', n = ' + (Lua-Str $m.nombre) + ', p = ' + (Lua-Str $m.pack) + ', pn = ' + (Lua-Str $pn) + ', v = ' + (Lua-Str $m.veredicto) +
            ', i = ' + $(if ($inst.ContainsKey($m.id)) { 'true' } else { 'false' }) + ', a = ' + $(if ($activo[$m.id]) { 'true' } else { 'false' }) +
            ', ap = ' + $(if ($m.apagado) { 'true' } else { 'false' }) + ', rg = ' + (Lua-Str $rg) + ', d = ' + (Lua-Str $d) + ' },')
    }
    $L.Add('},')
    $L.Add('errores = {')
    foreach ($e in (Errores-Sesion | Select-Object -First 30)) {
        $L.Add('{ mod = ' + (Lua-Str $e.mod) + ', n = ' + $e.n + ', msg = ' + (Lua-Str $e.msg) + ', pila = ' + (Lua-Str $e.pila) + ' },')
    }
    $L.Add('}, }')
    $salida = Join-Path $dest 'panel_datos.lua'
    $it = Get-Item $salida -Force -ErrorAction SilentlyContinue
    if ($it -and $it.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-Item $salida -Force }   # nunca escribir a través de un enlace
    [IO.File]::WriteAllText($salida, (($L -join "`n") + "`n"), $script:utf8)
}

# Escáner por mod (mods\!!!isaac_pack_scanner\config.lua): mide cuánto tarda cada mod en sus callbacks. Pequeño coste, solo para diagnosticar.
function Escribir-Config-Escaner($activo) {
    $d = Join-Path $script:ModsDir '!!!isaac_pack_scanner'
    if (-not (Test-Path $d)) { return }
    $f = Join-Path $d 'config.lua'
    $it = Get-Item $f -Force -ErrorAction SilentlyContinue
    if ($it -and $it.Attributes -band [IO.FileAttributes]::ReparsePoint) { Remove-Item $f -Force }   # nunca escribir a través de un enlace
    [IO.File]::WriteAllText($f, ('return { activo = ' + $(if ($activo) { 'true' } else { 'false' }) + " }`n"), $script:utf8)
    Set-Content (Join-Path $script:Estado 'escaner.txt') $(if ($activo) { '1' } else { '0' })
}

# ---------------------------------------------------------------- Aplicar packs
# Activa/desactiva los mods según los packs (y órdenes sueltas), aplica el parche de Job y refresca el panel.
function Aplicar-Packs($elegidos, $on = @(), $off = @(), $ticksPendiente = $null, $scanner = $null) {
    Parche-Job
    $n = 0
    foreach ($m in $script:Mods) {
        if (-not $script:Instalados.ContainsKey($m.id)) { continue }
        $carpeta = $script:Instalados[$m.id]
        if (En-Workshop $carpeta) { continue }   # aún no copiado a mods\: se aplica en la próxima ejecución
        if ($m.id -eq '2567634705') { continue } # Job original: lo gestiona Parche-Job
        if (Debe-Estar-Activo $m $elegidos $on $off) { Quitar-Marca $carpeta } else { Poner-Marca $carpeta }
        $n++
    }
    if ($ticksPendiente) { Set-Content (Join-Path $script:Estado 'panel_aplicado.txt') ([string]$ticksPendiente) }
    Set-Content (Join-Path $script:Estado 'ultimo.txt') ($elegidos -join ',')
    Escribir-Panel $elegidos
    if ($null -ne $scanner) { Escribir-Config-Escaner ([bool]$scanner) }
    Log "$n mods configurados y panel del juego actualizado." 'ok'
    return $n
}

# Español: Language=4 (SPANISH en REPENTOGON) en options.ini y EID en «spa». El idioma que manda es el de Steam.
function Fijar-Idioma {
    $ini = Join-Path $env:USERPROFILE 'Documents\My Games\Binding of Isaac Repentance+\options.ini'
    if (Test-Path $ini) {
        $t = [IO.File]::ReadAllText($ini)
        $n = [regex]::Replace($t, '(?m)^Language=[^\r\n]*', 'Language=4')
        if ($n -ne $t) {
            Copy-Item $ini ($ini + '.bak_es') -Force
            [IO.File]::WriteAllText($ini, $n, $script:utf8)
            Log 'options.ini: Language=4 (español).' 'ok'
        } else { Log 'options.ini ya está en español.' 'ok' }
    } else { Log 'Aún no existe options.ini: abre Isaac una vez, ciérralo y vuelve a ejecutar.' 'aviso' }
    $eid = Join-Path $script:Juego 'data\external item descriptions'
    if (Test-Path $eid) {
        foreach ($f in (Get-ChildItem $eid -Filter 'save*.dat')) {
            $t = [IO.File]::ReadAllText($f.FullName)
            $n = [regex]::Replace($t, '"Language":"[^"]*"', '"Language":"spa"')
            $n = [regex]::Replace($n, '"TranslateItemName":\d', '"TranslateItemName":2')
            if ($n -ne $t) { [IO.File]::WriteAllText($f.FullName, $n, $script:utf8); Log "EID en español ($($f.Name))." 'ok' }
        }
    }
}

# ---------------------------------------------------------------- Suscripción a Workshop
function Texto-Suscripcion($faltan) {
    $ids = ($faltan | ForEach-Object { "'$($_.id)'" }) -join ','
    return "(async()=>{for(const id of [$ids]){const r=await fetch('/sharedfiles/subscribe',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({id,appid:'250900',sessionid:g_sessionID})});console.log(id,r.status);await new Promise(o=>setTimeout(o,800));}console.log('Hecho. Abre Steam y espera a que descargue.');})();"
}
function Mods-Que-Faltan($elegidos, $on = @(), $off = @()) {
    return @($script:Mods | Where-Object { (Debe-Estar-Activo $_ $elegidos $on $off) -and -not $_.no_suscribir -and -not $script:Instalados.ContainsKey($_.id) })
}

# ---------------------------------------------------------------- Jugar: todo en un clic
function Pausa($seg) {
    $fin = (Get-Date).AddSeconds($seg)
    while ((Get-Date) -lt $fin) { Start-Sleep -Milliseconds 250; if ($script:Tick) { & $script:Tick } }
}

# Copia a mods\ lo que Steam ya descargó en workshop\content (carpeta destino = <directory>_<id>, como hace el juego).
# El nombre viene del metadata.xml de un mod ajeno: solo se acepta un nombre simple dentro de mods\.
function Sincronizar-Workshop {
    if (-not (Test-Path $script:WorkshopDir)) { return 0 }
    $n = 0
    $modsCompleto = [IO.Path]::GetFullPath($script:ModsDir).TrimEnd('\')
    foreach ($d in (Get-ChildItem $script:WorkshopDir -Directory)) {
        $meta = Join-Path $d.FullName 'metadata.xml'
        if (-not (Test-Path $meta)) { continue }
        $ya = Get-ChildItem $script:ModsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match ('_' + [regex]::Escape($d.Name) + '$') } | Select-Object -First 1
        if ($ya) { continue }
        $m = [regex]::Match([IO.File]::ReadAllText($meta), '<directory>(.*?)</directory>', 'Singleline')
        if (-not $m.Success) { continue }
        $nombre = $m.Groups[1].Value.Trim()
        if ($nombre -notmatch '^[\w .\-()\[\]''`!+&]+$' -or $nombre -eq '.' -or $nombre -eq '..') { Log "Nombre de carpeta sospechoso en $($d.Name): se omite." 'aviso'; continue }
        $dest = Join-Path $script:ModsDir ($nombre + '_' + $d.Name)
        if ((Split-Path ([IO.Path]::GetFullPath($dest))).TrimEnd('\') -ne $modsCompleto) { continue }
        if (Test-Path $dest) { continue }
        Copy-Item $d.FullName $dest -Recurse
        $n++
    }
    return $n
}

function Ruta-Steam {
    $r = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamExe
    if ($r) { return ($r -replace '/', '\') }
    return $null
}

# Steam tiene que estar abierto ANTES del lanzador: si no, Isaac sale al instante y Steam abre la versión sin REPENTOGON.
function Asegurar-Steam {
    if (Steam-Abierto) { return $true }
    $exe = Ruta-Steam
    if (-not $exe -or -not (Test-Path $exe)) { Log 'No encuentro Steam: ábrelo tú, inicia sesión y vuelve a pulsar Jugar.' 'aviso'; return $false }
    Log 'Abriendo Steam (puede tardar un poco)…'
    Start-Process $exe -ArgumentList '-silent'
    $fin = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $fin -and -not (Get-Process -Name 'steamwebhelper' -ErrorAction SilentlyContinue)) { Pausa 1 }
    if (-not (Get-Process -Name 'steamwebhelper' -ErrorAction SilentlyContinue)) { Log 'Steam no terminó de abrirse. Ábrelo tú, inicia sesión y vuelve a pulsar Jugar.' 'aviso'; return $false }
    Log 'Steam abierto. Esperando a que inicie sesión…'
    Pausa 20
    return $true
}

# Lanza Isaac con REPENTOGON y comprueba que de verdad cargó (ruta ...\Repentogon\isaac-ng.exe) y no la versión normal.
function Lanzar-Isaac {
    if (Isaac-Abierto) { Log 'Isaac ya está abierto: ciérralo del todo (si ves «REPENTOGON REQUIRED», es la versión sin REPENTOGON) y vuelve a pulsar Jugar.' 'aviso'; return $false }
    $lanz = Join-Path $script:Juego 'REPENTOGONLauncher\REPENTOGONLauncher.exe'
    if (-not (Test-Path $lanz)) { Log 'El lanzador de REPENTOGON no está instalado: pulsa «Instalar / actualizar todo».' 'aviso'; return $false }
    if (Get-Process -Name 'REPENTOGONLauncher' -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path -ieq $lanz }) { Log 'El lanzador de REPENTOGON ya está abierto. Espera a que termine antes de volver a pulsar Jugar.' 'aviso'; return $false }
    $ini = Ruta-Ini-Lanzador
    if (Test-Path $ini) {
        [void](Configurar-Ruta-Lanzador)
        Start-Process $lanz -ArgumentList '--stealth-mode' -WorkingDirectory (Split-Path $lanz)
    } else {
        Log 'Primera vez con el lanzador: puede abrirse su ventana de configuración; acepta lo que propone y pulsa Jugar otra vez.' 'aviso'
        Start-Process $lanz -WorkingDirectory (Split-Path $lanz)
        return $true
    }
    Log 'Lanzando Isaac con REPENTOGON…'
    $p = $null
    $fin = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $fin -and -not $p) { Pausa 1; $p = Get-Process -Name 'isaac-ng' -ErrorAction SilentlyContinue | Select-Object -First 1 }
    if (-not $p) { Log 'Isaac no llegó a abrirse. Mira el registro del lanzador (REPENTOGONLauncher\launcher.log). Con Smart App Control activo el lanzador no puede arrancar.' 'error'; return $false }
    Pausa 8   # por si Steam relanza la versión normal
    $p = Get-Process -Name 'isaac-ng' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p -and $p.Path -and $p.Path -like '*\Repentogon\*') { Log 'Isaac abierto con REPENTOGON. ¡A jugar!' 'ok'; return $true }
    if ($p) { Log 'Se abrió Isaac SIN REPENTOGON. Ciérralo del todo y pulsa Jugar otra vez (con Steam ya abierto).' 'aviso'; return $false }
    Log 'Isaac se cerró nada más abrirse. Pulsa Jugar otra vez; si se repite, revisa el registro del lanzador.' 'aviso'
    return $false
}
