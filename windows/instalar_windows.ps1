# Isaac Pack ES · instalador de Windows 10/11 en modo consola (la ventana está en instalar_gui.ps1).
# Hace lo mismo que la ventana: localiza Isaac en Steam, instala lo que NO es de Workshop (lanzador de REPENTOGON, traducción
# y panel del juego), te dice qué mods de Workshop faltan, aplica la corrección de Job y activa los packs.
#   -Rapido  no pregunta nada: aplica lo guardado en el panel del juego (o tu última elección) y refresca el panel.
# Contacto: https://www.instagram.com/_shun._05/
param([string]$Juego, [switch]$Rapido)

$ErrorActionPreference = 'Stop'
$Raiz = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $PSScriptRoot 'lib.ps1')
$script:LogFn = {
    param($t, $nivel)
    switch ($nivel) {
        'ok'    { Write-Host "   [OK] $t" -ForegroundColor Green }
        'aviso' { Write-Host "   [!]  $t" -ForegroundColor Yellow }
        default { Write-Host "   $t" }
    }
}
function Titulo($t) { Write-Host ''; Write-Host "== $t" -ForegroundColor Cyan }

Write-Host ''
Write-Host "  Isaac Pack ES v$script:Version · instalador para Windows" -ForegroundColor White
Write-Host '  The Binding of Isaac: Repentance+ · mods en español' -ForegroundColor DarkGray

Titulo '1. Buscando Isaac en Steam'
if (-not $Juego) { $Juego = Buscar-Juego }
if (-not $Juego) {
    Log 'No encuentro Isaac automáticamente.' 'aviso'
    $Juego = Read-Host '   Pega la ruta de la carpeta del juego (donde está isaac-ng.exe)'
}
if (-not (Iniciar-Contexto $Juego)) { throw "No hay isaac-ng.exe en '$Juego'. Instala Isaac desde Steam y vuelve a ejecutar." }
if (Isaac-Abierto) { throw 'Isaac está abierto. Ciérralo del todo y vuelve a ejecutar.' }
Log $Juego 'ok'

Titulo '2. ¿Qué quieres jugar?'
$pend = Leer-Pendiente
$on = @(); $off = @()
if ($pend) {
    $elegidos = @('base') + @($pend.packs | Where-Object { $script:Packs.Contains($_) -and $_ -ne 'base' })
    $on = @($pend.on | ForEach-Object { "$_" }); $off = @($pend.off | ForEach-Object { "$_" })
    Log ('Usando la selección guardada en el panel del juego: ' + (($elegidos | ForEach-Object { $script:Packs[$_] }) -join ', ')) 'ok'
} elseif ($Rapido -and (Test-Path (Join-Path $script:Estado 'ultimo.txt'))) {
    $elegidos = @((Get-Content (Join-Path $script:Estado 'ultimo.txt') -Raw).Trim() -split ',')
    Log ('Repitiendo tu última elección: ' + (($elegidos | ForEach-Object { $script:Packs[$_] }) -join ', ')) 'ok'
} else {
    Write-Host '   1) Clean (recomendado): calidad de vida, interfaz, rendimiento, sinergias y visual'
    Write-Host '   2) Completo: todo, también expansiones grandes, caprichos y trucos (puede dar choques)'
    Write-Host '   3) Mínimo: solo calidad de vida, interfaz y rendimiento'
    $op = Read-Host '   Elige 1, 2 o 3 [1]'
    $nombre = @{ '1' = 'clean'; '2' = 'completo'; '3' = 'minimo' }[$op]
    if (-not $nombre) { $nombre = 'clean' }
    $elegidos = $script:Presets[$nombre]
    Log ('Packs: ' + (($elegidos | ForEach-Object { $script:Packs[$_] }) -join ', ')) 'ok'
}

Titulo '3. Instalando lo que no es de Workshop'
[void](Instalar-Lanzador)
Crear-Acceso
Instalar-Locales

Titulo '4. Mods de Workshop'
[void](Leer-Instalados)
$faltan = Mods-Que-Faltan $elegidos $on $off
$necesarios = @($script:Mods | Where-Object { (Debe-Estar-Activo $_ $elegidos $on $off) -and -not $_.no_suscribir })
Log "$($necesarios.Count - $faltan.Count) de $($necesarios.Count) mods de tu selección ya están descargados." 'ok'
if ($faltan.Count -gt 0 -and -not $Rapido) {
    Log "Faltan $($faltan.Count) mods de Workshop:" 'aviso'
    $faltan | ForEach-Object { Write-Host "       - $($_.nombre)" }
    Write-Host ''
    Write-Host '   Steam solo deja suscribirse con tu sesión. Elige cómo:'
    Write-Host '   1) Suscribirme a todos de golpe (copio un script; lo pegas en steamcommunity.com)'
    Write-Host '   2) Abrir la página de cada mod en la aplicación de Steam (clic en Suscribirse)'
    Write-Host '   3) Nada ahora'
    $o = Read-Host '   Elige 1, 2 o 3 [1]'
    if ($o -eq '2') {
        foreach ($m in $faltan) { Start-Process "steam://url/CommunityFilePage/$($m.id)"; Start-Sleep -Seconds 3 }
        Log 'Se han abierto en Steam. Pulsa «Suscribirse» en cada una.' 'aviso'
    } elseif ($o -ne '3') {
        Set-Clipboard -Value (Texto-Suscripcion $faltan)
        Start-Process 'https://steamcommunity.com/my/'
        Write-Host ''
        Write-Host '   Hecho: el script está COPIADO al portapapeles. Ahora:'
        Write-Host '     1. En la página que se abre, inicia sesión en Steam si no lo estás.'
        Write-Host '     2. Pulsa F12, ve a la pestaña «Consola», pega con Ctrl+V y pulsa Intro.'
        Write-Host '     3. Abre Steam y espera a que termine de descargar.'
    }
} elseif ($faltan.Count -gt 0) {
    Log "Faltan $($faltan.Count) mods por suscribir: ejecuta el instalador normal (sin -Rapido) para suscribirte." 'aviso'
}

Titulo '5. Activando tus packs'
[void](Aplicar-Packs $elegidos $on $off $(if ($pend) { $pend.ticks } else { $null }) $(if ($pend -and $null -ne $pend.scanner) { [bool]$pend.scanner } else { $null }))
Log 'Los mods recién descargados aparecen en la carpeta mods al abrir Isaac por primera vez. Cuando termine de cargar, cierra el juego y VUELVE A EJECUTAR este instalador (o Aplicar_seleccion.bat) para activar solo tus packs.' 'aviso'

Titulo '6. Español y panel'
Fijar-Idioma
if (-not (Test-Path (Join-Path $script:Juego 'Repentogon\isaac-ng.exe'))) { [void](Abrir-Reparacion-Repentogon) }
Write-Host '   IMPORTANTE: Steam > Biblioteca > The Binding of Isaac > clic derecho > Propiedades > Idioma > Español.'
Write-Host '   Si sigue en inglés: abre el lanzador de REPENTOGON, «Change Game Options» y elige el idioma ahí.'
Write-Host '   Dentro del juego, con REPENTOGON: pulsa ~ y abre «Packs ES», o pulsa F9, para elegir packs y mods.'
Write-Host '   Después de guardar en el panel, cierra Isaac y ejecuta Aplicar_seleccion.bat.'
Write-Host ''
Write-Host '   Cuando termine la instalación o reparación, abre Isaac con «Isaac con REPENTOGON» (Escritorio), con Steam abierto.' -ForegroundColor Green
