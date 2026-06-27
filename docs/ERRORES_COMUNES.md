# Errores comunes de Cursed Walking MOD Live

Esta guia deja anotados los fallos reales que aparecieron al publicar `cursed-walking-mod-live` y como revisarlos sin tocar a ciegas el paquete.

## Publicada antigua en la app

Sintoma:

- La app muestra `Instalada v0.1.4`, pero `Publicada v0.1.2` o una version vieja.

Causa mas probable:

- El backend publico todavia esta desplegado en un commit viejo o el WebView mantiene cache local del catalogo.

Revision:

- Revisar `/health` del backend y confirmar que el commit sea el ultimo publicado.
- Revisar que `data/games.json` apunte a la version, ZIP, tamano y SHA correctos.
- Cerrar y abrir la app. Si sigue igual, limpiar solo cache/sesion WebView, no borrar juegos.

Parche aplicado:

- El backend publico ahora envia `Cache-Control: no-store` en catalogo, regalos y descargas publicas.

## EULA del servidor

Sintoma:

- La app dice que el servidor Minecraft no arranca porque falta aceptar la EULA en `server/eula.txt`.

Causa:

- El paquete publico o la instalacion local no traia `eula=true`.

Revision:

- Confirmar que `server/eula.txt` exista y contenga `eula=true`.
- Validar que el ZIP publicado tambien lo incluya, no solo la carpeta local.

Parche aplicado:

- Desde `v0.1.3` el paquete publicado incluye `server/eula.txt` con `eula=true`.

## JAVA_HOME nulo al preparar cliente

Sintoma:

- La instalacion queda incompleta.
- `logs/launcher/prepare-client-install.log` muestra:

```text
Join-Path : No se puede enlazar el argumento al parametro 'Path' porque es nulo.
```

Causa:

- `scripts/preparar_cliente.ps1` intentaba usar `$env:JAVA_HOME` aunque en la PC del usuario estaba vacio.

Revision:

- Abrir `prepare-client-install.log`.
- Confirmar si aparece `JAVA_HOME` o `Join-Path`.

Parche aplicado:

- Desde `v0.1.4`, `Find-Java` valida si `JAVA_HOME` existe antes de usarlo.
- Tambien busca Java portable en `tools/java/bin/java.exe` y Java del sistema.

## REQUEST_FAILED al iniciar desde Minecraft Launcher

Sintoma:

- Minecraft Launcher muestra `Unable to prepare assets for download`.

Causas posibles:

- Perfil Minecraft generado incompleto.
- Assets/libraries faltantes o cache corrupta del launcher.
- Se intento abrir un perfil viejo en vez del perfil instalado por la app.

Revision:

- Ejecutar `scripts/preparar_cliente.ps1`.
- Abrir el perfil `Cursed Walking MOD Live` creado por la app.
- Revisar logs del launcher y `logs/launcher/preparar-cliente.log`.

Nota:

- Este fallo es del launcher preparando el cliente, no del EventBus ni de RCON.

## Mismatched mod channel list

Sintoma:

- Minecraft conecta al servidor pero expulsa con `mismatched mod channel list`.
- El mensaje dice que al servidor le faltan mods como `Ponder`, `Create`, `Particular` u otros.

Causa:

- Cliente y servidor no tienen el mismo conjunto de mods esperado.
- Tambien pasa si se abre otro perfil del launcher, no el perfil generado por la app.

Revision:

- Usar la instalacion `Cursed Walking MOD Live`.
- Reinstalar/actualizar el juego desde la app.
- Confirmar que `scripts/preparar_servidor.ps1` copie mods de servidor y omita solo mods cliente.

## No conecta al servidor local

Sintoma:

- En multiplayer sale `Can't connect to server`.

Causas posibles:

- El servidor todavia esta arrancando.
- Puerto incorrecto.
- EULA no aceptada.
- Otro proceso ocupa el puerto.
- El servidor crasheo durante arranque.

Revision:

- Usar el puerto que muestra la app en la tarjeta del juego.
- Revisar `logs/launcher/server.log`.
- Revisar `server/logs/latest.log`.
- Esperar a que el servidor termine de iniciar antes de entrar.

## Checklist antes de publicar

Antes de subir una version publica:

1. Bump de version en `game-manifest.json`.
2. Ejecutar `scripts/preparar_cliente.ps1` con `JAVA_HOME` vacio.
3. Ejecutar `scripts/preparar_servidor.ps1`.
4. Validar ZIP con `scripts/validar_paquete_juego.ps1`.
5. Confirmar dentro del ZIP: manifest, scripts, `server/eula.txt`, mods y assets.
6. Actualizar `data/games.json` con version, URL, tamano y SHA.
7. Confirmar que el backend desplegado sirve el catalogo nuevo.
8. Probar instalar desde una carpeta limpia.
