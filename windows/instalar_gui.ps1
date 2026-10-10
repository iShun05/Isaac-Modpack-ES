# Isaac Pack ES · instalador de Windows 10/11 con ventana (tema oscuro).
# Misma lógica que instalar_windows.ps1 (consola): comparten windows\lib.ps1.
# Contacto: https://www.instagram.com/_shun._05/
param([string]$Juego)

$ErrorActionPreference = 'Stop'
trap {
    try { Add-Type -AssemblyName System.Windows.Forms; [void][Windows.Forms.MessageBox]::Show("No se pudo abrir la ventana:`r`n`r`n$($_.Exception.Message)`r`n`r`nUsa Instalar_Windows_consola.bat.", 'Isaac Pack ES', 'OK', 'Error') } catch { }
    exit 1
}
$Raiz = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $PSScriptRoot 'lib.ps1')

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    Add-Type -Namespace Win -Name Dpi -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
    [void][Win.Dpi]::SetProcessDPIAware()
} catch { }
[Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------- colores y helpers
$cFondo  = [Drawing.Color]::FromArgb(0, 0, 0)
$cPanel  = [Drawing.Color]::FromArgb(16, 16, 22)
$cTexto  = [Drawing.Color]::FromArgb(232, 232, 238)
$cMut    = [Drawing.Color]::FromArgb(138, 138, 150)
$cAcento = [Drawing.Color]::FromArgb(169, 139, 255)

function Nuevo-Boton($texto, $ancho, $primario = $false) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $texto; $b.Width = $ancho; $b.Height = 36; $b.FlatStyle = 'Flat'; $b.Cursor = 'Hand'
    $b.FlatAppearance.BorderSize = 1; $b.FlatAppearance.BorderColor = $cAcento
    if ($primario) { $b.BackColor = $cAcento; $b.ForeColor = $cFondo } else { $b.BackColor = $cPanel; $b.ForeColor = $cTexto }
    $b.Margin = New-Object Windows.Forms.Padding(0, 0, 8, 8)
    return $b
}
function Nueva-Etiqueta($texto, $tam = 9.5, $color = $null, $negrita = $false) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $texto; $l.AutoSize = $true
    $estilo = if ($negrita) { [Drawing.FontStyle]::Bold } else { [Drawing.FontStyle]::Regular }
    $l.Font = New-Object Drawing.Font('Segoe UI', $tam, $estilo)
    $l.ForeColor = if ($color) { $color } else { $cTexto }
    return $l
}
function Nueva-Lista {
    $c = New-Object Windows.Forms.CheckedListBox
    $c.Dock = 'Fill'; $c.BackColor = $cPanel; $c.ForeColor = $cTexto; $c.BorderStyle = 'None'
    $c.CheckOnClick = $true; $c.IntegralHeight = $false
    return $c
}

# ---------------------------------------------------------------- ventana
$f = New-Object Windows.Forms.Form
$f.Text = "Isaac Pack ES v$script:Version"
$f.Size = New-Object Drawing.Size(960, 760)
$f.MinimumSize = New-Object Drawing.Size(820, 640)
$f.StartPosition = 'CenterScreen'
$f.BackColor = $cFondo; $f.ForeColor = $cTexto
$f.Font = New-Object Drawing.Font('Segoe UI', 9.5)

# cabecera
$pnlTop = New-Object Windows.Forms.Panel
$pnlTop.Dock = 'Top'; $pnlTop.Height = 84; $pnlTop.BackColor = $cFondo; $pnlTop.Padding = New-Object Windows.Forms.Padding(18, 10, 18, 6)
$lblTitulo = Nueva-Etiqueta 'Isaac Pack ES' 17 $cAcento $true
$lblTitulo.Location = New-Object Drawing.Point(18, 8)
$lblSub = Nueva-Etiqueta "The Binding of Isaac: Repentance+ · mods en español · v$script:Version" 9 $cMut
$lblSub.Location = New-Object Drawing.Point(20, 42)
$lblJuego = Nueva-Etiqueta '' 9 $cMut
$lblJuego.Location = New-Object Drawing.Point(20, 62)
$btnCambiar = Nuevo-Boton 'Cambiar carpeta…' 150
$btnCambiar.Height = 30; $btnCambiar.Anchor = 'Top, Right'; $btnCambiar.Location = New-Object Drawing.Point(770, 26)
$pnlTop.Controls.AddRange(@($lblTitulo, $lblSub, $lblJuego, $btnCambiar))

# centro: packs | mods
$tlp = New-Object Windows.Forms.TableLayoutPanel
$tlp.Dock = 'Fill'; $tlp.ColumnCount = 2; $tlp.RowCount = 1; $tlp.BackColor = $cFondo; $tlp.Padding = New-Object Windows.Forms.Padding(14, 0, 14, 0)
[void]$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent', 40)))
[void]$tlp.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent', 60)))

$pnlIzq = New-Object Windows.Forms.Panel; $pnlIzq.Dock = 'Fill'; $pnlIzq.Padding = New-Object Windows.Forms.Padding(4, 0, 8, 0)
$clbPacks = Nueva-Lista
$flowPre = New-Object Windows.Forms.FlowLayoutPanel; $flowPre.Dock = 'Top'; $flowPre.Height = 44; $flowPre.BackColor = $cFondo
$btnClean = Nuevo-Boton 'Clean' 78; $btnCompleto = Nuevo-Boton 'Completo' 92; $btnMinimo = Nuevo-Boton 'Mínimo' 84
$flowPre.Controls.AddRange(@($btnClean, $btnCompleto, $btnMinimo))
$lblPacks = Nueva-Etiqueta 'Packs (elige los que quieres jugar)' 10 $cTexto $true
$lblPacks.Dock = 'Top'; $lblPacks.Height = 26
$pnlIzq.Controls.Add($clbPacks); $pnlIzq.Controls.Add($flowPre); $pnlIzq.Controls.Add($lblPacks)

$pnlDer = New-Object Windows.Forms.Panel; $pnlDer.Dock = 'Fill'; $pnlDer.Padding = New-Object Windows.Forms.Padding(8, 0, 4, 0)
$clbMods = Nueva-Lista
$lblMods = Nueva-Etiqueta 'Mods (avanzado: casilla = activo)' 10 $cTexto $true
$lblMods.Dock = 'Top'; $lblMods.Height = 26
$pnlDer.Controls.Add($clbMods); $pnlDer.Controls.Add($lblMods)
$tlp.Controls.Add($pnlIzq, 0, 0); $tlp.Controls.Add($pnlDer, 1, 0)

# botones de acción
$pnlAcc = New-Object Windows.Forms.Panel
$pnlAcc.Dock = 'Bottom'; $pnlAcc.Height = 132; $pnlAcc.BackColor = $cFondo; $pnlAcc.Padding = New-Object Windows.Forms.Padding(18, 6, 18, 0)
$lblEstado = Nueva-Etiqueta '' 9.5 $cMut
$lblEstado.Dock = 'Top'; $lblEstado.Height = 26
$flowAcc = New-Object Windows.Forms.FlowLayoutPanel; $flowAcc.Dock = 'Fill'; $flowAcc.BackColor = $cFondo
$btnInstalar = Nuevo-Boton 'Instalar / actualizar todo' 210 $true
$btnSuscribir = Nuevo-Boton 'Suscribirme a lo que falta' 200
$btnSteam = Nuevo-Boton 'Abrir páginas en Steam' 170
$btnAplicar = Nuevo-Boton 'Aplicar selección' 150
$btnJugar = Nuevo-Boton '▶  JUGAR' 190 $true
$btnJugar.Height = 46; $btnJugar.Font = New-Object Drawing.Font('Segoe UI', 12, [Drawing.FontStyle]::Bold)
$flowAcc.Controls.AddRange(@($btnJugar, $btnInstalar, $btnSuscribir, $btnSteam, $btnAplicar))
$pnlAcc.Controls.Add($flowAcc); $pnlAcc.Controls.Add($lblEstado)

# registro
$txtLog = New-Object Windows.Forms.TextBox
$txtLog.Dock = 'Bottom'; $txtLog.Height = 170; $txtLog.Multiline = $true; $txtLog.ReadOnly = $true; $txtLog.ScrollBars = 'Vertical'
$txtLog.BackColor = $cPanel; $txtLog.ForeColor = $cTexto; $txtLog.BorderStyle = 'None'; $txtLog.Font = New-Object Drawing.Font('Consolas', 9.5)

# el orden de alta decide el apilado: primero el centro, luego lo que va pegado a los bordes
$f.Controls.Add($tlp); $f.Controls.Add($pnlAcc); $f.Controls.Add($txtLog); $f.Controls.Add($pnlTop)

$script:Tick = { [Windows.Forms.Application]::DoEvents() }
$script:LogFn = {
    param($t, $nivel)
    $pre = switch ($nivel) { 'ok' { '[OK] ' } 'aviso' { '[!]  ' } 'error' { '[X]  ' } default { '' } }
    $txtLog.AppendText(('{0}  {1}{2}' -f (Get-Date -Format 'HH:mm:ss'), $pre, $t) + "`r`n")
    [Windows.Forms.Application]::DoEvents()
}

# ---------------------------------------------------------------- estado de la ventana
$script:PackKeys = @()
$script:ModItems = @()
$script:Ovr = @{}            # id de mod -> true/false (anula lo que diga su pack)
$script:Actualizando = $false
$script:Pend = $null

function Packs-Elegidos {
    $r = @('base')
    for ($i = 0; $i -lt $script:PackKeys.Count; $i++) { if ($clbPacks.GetItemChecked($i)) { $r += $script:PackKeys[$i] } }
    return $r
}
function Ordenes-Sueltas {
    $on = @(); $off = @()
    foreach ($k in $script:Ovr.Keys) { if ($script:Ovr[$k]) { $on += $k } else { $off += $k } }
    return @{ on = $on; off = $off }
}
function Pintar-Mods {
    $script:Actualizando = $true
    $el = Packs-Elegidos; $o = Ordenes-Sueltas
    for ($i = 0; $i -lt $script:ModItems.Count; $i++) { $clbMods.SetItemChecked($i, [bool](Debe-Estar-Activo $script:ModItems[$i] $el $o.on $o.off)) }
    $script:Actualizando = $false
}
function Poner-Packs($lista) {
    $script:Actualizando = $true
    for ($i = 0; $i -lt $script:PackKeys.Count; $i++) { $clbPacks.SetItemChecked($i, ($lista -contains $script:PackKeys[$i])) }
    $script:Actualizando = $false
}
function Refrescar-Estado {
    [void](Leer-Instalados)
    $el = Packs-Elegidos; $o = Ordenes-Sueltas
    $nec = @($script:Mods | Where-Object { (Debe-Estar-Activo $_ $el $o.on $o.off) -and -not $_.no_suscribir })
    $falt = Mods-Que-Faltan $el $o.on $o.off
    $lblEstado.Text = "Mods elegidos: $($nec.Count) · descargados: $($nec.Count - $falt.Count) · faltan: $($falt.Count)" + $(if (Isaac-Abierto) { '   ⚠ Isaac está abierto: ciérralo para aplicar cambios.' } else { '' })
    $btnSuscribir.Enabled = ($falt.Count -gt 0); $btnSteam.Enabled = ($falt.Count -gt 0)
}
function Cargar-Lista {
    $script:PackKeys = @(); $clbPacks.Items.Clear(); $clbMods.Items.Clear(); $script:ModItems = @()
    foreach ($k in $script:Packs.Keys) { if ($k -ne 'base') { $script:PackKeys += $k; [void]$clbPacks.Items.Add($script:Packs[$k]) } }
    $orden = @($script:Packs.Keys)
    $script:ModItems = @($script:Mods | Where-Object { $_.pack -ne 'descartado' } | Sort-Object @{ Expression = { $orden.IndexOf($_.pack) } }, @{ Expression = { $_.nombre.ToLower() } })
    foreach ($m in $script:ModItems) {
        $pn = if ($script:Packs.Contains($m.pack)) { $script:Packs[$m.pack] } else { $m.pack }
        [void]$clbMods.Items.Add(("{0}   ·   {1} · {2}" -f $m.nombre, $pn, $m.veredicto))
    }
    $ultimo = Join-Path $script:Estado 'ultimo.txt'
    if (Test-Path $ultimo) { Poner-Packs @((Get-Content $ultimo -Raw).Trim() -split ',') } else { Poner-Packs $script:Presets['clean'] }
    $script:Pend = Leer-Pendiente
    if ($script:Pend) {
        Poner-Packs @($script:Pend.packs)
        foreach ($id in @($script:Pend.on)) { $script:Ovr["$id"] = $true }
        foreach ($id in @($script:Pend.off)) { $script:Ovr["$id"] = $false }
        Log 'Selección guardada en el panel del juego cargada.' 'ok'
    }
    Pintar-Mods
    Refrescar-Estado
}
function Usar-Juego($carpeta) {
    if (-not (Iniciar-Contexto $carpeta)) { return $false }
    $lblJuego.Text = "Carpeta de Isaac: $carpeta"
    Cargar-Lista
    return $true
}

# casillas: un pack arrastra a sus mods; un mod suelto queda como orden manual
$clbPacks.Add_ItemCheck({
    param($s, $e)
    if ($script:Actualizando) { return }
    $k = $script:PackKeys[$e.Index]; $v = ($e.NewValue -eq 'Checked')
    $script:Actualizando = $true
    for ($i = 0; $i -lt $script:ModItems.Count; $i++) {
        $m = $script:ModItems[$i]
        if ($m.pack -eq $k) { $script:Ovr.Remove($m.id); $clbMods.SetItemChecked($i, ($v -and -not $m.apagado)) }
    }
    $script:Actualizando = $false
})
$clbMods.Add_ItemCheck({
    param($s, $e)
    if ($script:Actualizando) { return }
    $script:Ovr[$script:ModItems[$e.Index].id] = ($e.NewValue -eq 'Checked')
})
$clbMods.Add_SelectedIndexChanged({
    $i = $clbMods.SelectedIndex
    if ($i -ge 0 -and $i -lt $script:ModItems.Count) { $lblEstado.Text = [string]$script:ModItems[$i].descripcion }
})
function Aplicar-Preset($nombre) {
    Poner-Packs $script:Presets[$nombre]
    $script:Ovr = @{}
    Pintar-Mods
    Refrescar-Estado
}
$btnClean.Add_Click({ Aplicar-Preset 'clean' })
$btnCompleto.Add_Click({ Aplicar-Preset 'completo' })
$btnMinimo.Add_Click({ Aplicar-Preset 'minimo' })

# ejecuta una acción con los botones bloqueados y los errores a la vista
function Ejecutar-Seguro([scriptblock]$bloque) {
    foreach ($c in $flowAcc.Controls) { $c.Enabled = $false }
    try { & $bloque }
    catch {
        Log ("ERROR: " + $_.Exception.Message) 'error'
        [void][Windows.Forms.MessageBox]::Show("Algo ha fallado:`r`n`r`n" + $_.Exception.Message + "`r`n`r`nCopia el texto del registro de abajo si necesitas ayuda.", 'Isaac Pack ES', 'OK', 'Error')
    }
    finally { foreach ($c in $flowAcc.Controls) { $c.Enabled = $true }; Refrescar-Estado }
}
function Aviso-Cerrar-Isaac {
    if (Isaac-Abierto) { [void][Windows.Forms.MessageBox]::Show('Isaac está abierto. Ciérralo del todo y vuelve a pulsar.', 'Isaac Pack ES', 'OK', 'Warning'); return $true }
    return $false
}

$btnInstalar.Add_Click({
    Ejecutar-Seguro {
        if (Aviso-Cerrar-Isaac) { return }
        $el = Packs-Elegidos; $o = Ordenes-Sueltas
        Log 'Instalando lo que no es de Workshop…'
        [void](Instalar-Lanzador); Crear-Acceso; Instalar-Locales
        [void](Leer-Instalados)
        $falt = Mods-Que-Faltan $el $o.on $o.off
        Log "Faltan $($falt.Count) mods de Workshop." $(if ($falt.Count -gt 0) { 'aviso' } else { 'ok' })
        [void](Aplicar-Packs $el $o.on $o.off $(if ($script:Pend) { $script:Pend.ticks } else { $null }))
        Fijar-Idioma
        $txt = "Listo.`r`n`r`n"
        if ($falt.Count -gt 0) { $txt += "Faltan $($falt.Count) mods de Workshop: pulsa «Suscribirme a lo que falta» (o «Abrir páginas en Steam»).`r`n`r`n" }
        $txt += "Después abre Isaac una vez con «Abrir Isaac (REPENTOGON)», ciérralo y pulsa «Aplicar selección» para activar solo tus packs.`r`n`r`nIMPORTANTE: Steam > Isaac > Propiedades > Idioma > Español."
        [void][Windows.Forms.MessageBox]::Show($txt, 'Isaac Pack ES', 'OK', 'Information')
    }
})

$btnSuscribir.Add_Click({
    Ejecutar-Seguro {
        $o = Ordenes-Sueltas
        $falt = Mods-Que-Faltan (Packs-Elegidos) $o.on $o.off
        if ($falt.Count -eq 0) { Log 'No falta ningún mod por suscribir.' 'ok'; return }
        Set-Clipboard -Value (Texto-Suscripcion $falt)
        Start-Process 'https://steamcommunity.com/my/'
        Log "Script de suscripción ($($falt.Count) mods) copiado al portapapeles." 'ok'
        [void][Windows.Forms.MessageBox]::Show("He copiado un script al portapapeles y he abierto steamcommunity.com.`r`n`r`n1. Inicia sesión en Steam si no lo estás.`r`n2. Pulsa F12 y abre la pestaña «Consola».`r`n3. Pega con Ctrl+V y pulsa Intro. (Si el navegador pide escribir «allow pasting», escríbelo y repite.)`r`n4. Abre Steam y espera a que descargue.", 'Suscribirme a lo que falta', 'OK', 'Information')
    }
})

$btnSteam.Add_Click({
    Ejecutar-Seguro {
        $o = Ordenes-Sueltas
        $falt = Mods-Que-Faltan (Packs-Elegidos) $o.on $o.off
        if ($falt.Count -eq 0) { Log 'No falta ningún mod por suscribir.' 'ok'; return }
        if ($falt.Count -gt 8) {
            $r = [Windows.Forms.MessageBox]::Show("Se van a abrir $($falt.Count) páginas en Steam, una cada 3 segundos. ¿Seguro?", 'Isaac Pack ES', 'YesNo', 'Question')
            if ($r -ne 'Yes') { return }
        }
        foreach ($m in $falt) { Log "Abriendo en Steam: $($m.nombre)"; Start-Process "steam://url/CommunityFilePage/$($m.id)"; Start-Sleep -Seconds 3 }
        Log 'Pulsa «Suscribirse» en cada página.' 'aviso'
    }
})

$btnAplicar.Add_Click({
    Ejecutar-Seguro {
        if (Aviso-Cerrar-Isaac) { return }
        $el = Packs-Elegidos; $o = Ordenes-Sueltas
        [void](Leer-Instalados)
        [void](Aplicar-Packs $el $o.on $o.off $(if ($script:Pend) { $script:Pend.ticks } else { $null }))
        Log 'Selección aplicada. Abre Isaac con REPENTOGON.' 'ok'
    }
})

$btnJugar.Add_Click({
    Ejecutar-Seguro {
        if (Aviso-Cerrar-Isaac) { return }
        $el = Packs-Elegidos; $o = Ordenes-Sueltas
        [void](Leer-Instalados)
        $falt = Mods-Que-Faltan $el $o.on $o.off
        if ($falt.Count -gt 0) {
            $r = [Windows.Forms.MessageBox]::Show("Faltan $($falt.Count) mods de Workshop por suscribirte o descargar. Puedes jugar igualmente sin ellos, o cancelar y pulsar «Suscribirme a lo que falta».`r`n`r`n¿Jugar igualmente?", 'Isaac Pack ES', 'YesNo', 'Question')
            if ($r -ne 'Yes') { return }
        }
        [void](Instalar-Lanzador)
        Instalar-Locales
        $n = Sincronizar-Workshop
        if ($n -gt 0) { Log "Copiados $n mods recién descargados a la carpeta de mods." 'ok' }
        [void](Leer-Instalados)
        [void](Aplicar-Packs $el $o.on $o.off $(if ($script:Pend) { $script:Pend.ticks } else { $null }))
        Fijar-Idioma
        if (-not (Asegurar-Steam)) { return }
        [void](Lanzar-Isaac)
    }
})

$btnCambiar.Add_Click({
    $d = New-Object Windows.Forms.FolderBrowserDialog
    $d.Description = 'Elige la carpeta del juego (la que contiene isaac-ng.exe)'
    if ($d.ShowDialog() -eq 'OK') {
        if (-not (Usar-Juego $d.SelectedPath)) { [void][Windows.Forms.MessageBox]::Show('Esa carpeta no tiene isaac-ng.exe.', 'Isaac Pack ES', 'OK', 'Warning') }
    }
})

# ---------------------------------------------------------------- arranque
$f.Add_Shown({
    try {
        if (-not $Juego) { $script:J0 = Buscar-Juego } else { $script:J0 = $Juego }
        if ($script:J0 -and (Usar-Juego $script:J0)) {
            Log 'Isaac encontrado. Elige tus packs y pulsa «Instalar / actualizar todo».' 'ok'
        } else {
            $lblJuego.Text = 'No encuentro Isaac: pulsa «Cambiar carpeta…».'
            foreach ($c in $flowAcc.Controls) { $c.Enabled = $false }
            Log 'No encuentro Isaac en Steam. Instálalo y pulsa «Cambiar carpeta…».' 'aviso'
        }
    } catch {
        Log ("ERROR al iniciar: " + $_.Exception.Message) 'error'
    }
})
[void]$f.ShowDialog()
