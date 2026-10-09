// Suscribe tu cuenta a los 43 mods recomendados que faltan.
// Uso: abre steamcommunity.com con tu sesión iniciada, abre la consola del navegador y pega este archivo.
// Hace una petición POST a /sharedfiles/subscribe por mod (la misma que el botón «Suscribirse»). No toca tu contraseña.
// Para suscribirte solo a un pack, borra de la lista los ids que no quieras (nombres en docs/RECOMENDADOS.md).
(async () => {
  const ids = ["3701683951", "3445014938", "3381237554", "2499964071", "3374806352", "2917616737", "2769063897", "2627014611", "3134600246", "2376005362", "3334902042", "2910123966", "2916599212", "2897480136", "3408993906", "2996716893", "2965292371", "2529811350", "3033566163", "3797506645", "3778123093", "3655824749", "2880387531", "3012430463", "3599664675", "2603224299", "2503022727", "3461938404", "2661109135", "2980857979", "1230880928", "2978501842", "2722017893", "2567634705", "2570913695", "3783435722", "3585879877", "3599747427", "1933285222", "3363277114", "3778307529", "3622418481", "3305869734"];
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
