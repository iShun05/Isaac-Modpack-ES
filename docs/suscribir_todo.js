// Suscribe tu cuenta a los 0 mods recomendados que faltan.
// Uso: abre steamcommunity.com con tu sesión iniciada, abre la consola del navegador y pega este archivo.
// Hace una petición POST a /sharedfiles/subscribe por mod (la misma que el botón «Suscribirse»). No toca tu contraseña.
// Para suscribirte solo a un pack, borra de la lista los ids que no quieras (nombres en docs/RECOMENDADOS.md).
(async () => {
  const ids = [];
  for (const id of ids) {
    const r = await fetch('/sharedfiles/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ id, appid: '250900', sessionid: g_sessionID }),
    });
    console.log(id, r.status);
    await new Promise((ok) => setTimeout(ok, 800));
  }
  console.log('Hecho. Steam descargará los mods cuando esté abierto.');
})();
