# Cursed Walking MOD Live

Fuente local/admin creada desde `PLANTILLA_MINECRAFT_GENERAL` para conectar el modpack Cursed Walking con TikTok Live Games.

## Identidad

- `gameId`: `cursed-walking-mod-live`
- App/catalogo: `Cursed Walking MOD Live`
- Minecraft: `1.20.1`
- Forge: `47.4.0`
- Perfil: `Cursed Walking MOD Live`
- Carpeta aislada: `%APPDATA%\.minecraft\versions\CursedWalkingMODLive`
- EventBus: `http://127.0.0.1:9060/manifest`
- Servidor: `127.0.0.1:25572`
- RCON: `127.0.0.1:25582`

## Que incluye

- `game-manifest.json` con acciones para la app.
- `config/live_actions.json` con comandos editables y armas TACZ permitidas.
- `runtime/event_bus.py` HTTP local compatible con el launcher.
- `runtime/game_adapter.py` puente RCON con fallback a cola local.
- `game/overrides` copiado desde el export Cursed Walking V3.2.3.
- `game/mods` reconstruido desde el manifest CurseForge con 228 `.jar`.
- `curseforge/manifest.json` y `curseforge/modlist.html` como referencia del export original.
- `scripts/descargar_mods_curseforge.ps1` para reconstruir `game/mods` si falta algun `.jar`.
- `scripts/sincronizar_mod_arena.ps1` como compatibilidad con el launcher local actual.
- `stream-assets` con iconos y banners PNG grandes para overlays/catalogo.
- `docs` con arquitectura del proyecto y plan para reglas con comandos Minecraft.
- Scripts de preparar cliente, preparar servidor, iniciar y validar.

## Acciones iniciales

- Probar conexion.
- Curar jugador.
- Dar comida.
- Limpiar efectos.
- Caja de suministros.
- Dar armas TACZ/SFMS: AK-47, M4A1, MP5, M249, M107, M870, Minigun, RPG-7, SFMS M4A5.
- Dar arma configurada por `weaponKey`.
- Dar municion.
- Invocar horda.
- Zombie rapido.
- Rayo al jugador.
- Hacer de dia/noche.

## Como cambiar el arma especifica

Edita `config/live_actions.json`.

Para una accion fija, cambia el `weaponKey`:

```json
"give_weapon_ak47": {
  "weaponKey": "ak47"
}
```

Para la accion flexible:

```json
"give_configured_weapon": {
  "defaultWeaponKey": "m4a1",
  "allowPayloadWeaponKey": true
}
```

Las claves permitidas estan bajo `weapons`.

## Reconstruir mods

El repositorio no necesita subir los 228 `.jar` pesados. Para reconstruirlos:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\descargar_mods_curseforge.ps1 -Root .
```

Luego:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\preparar_cliente.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\preparar_servidor.ps1 -Root .
```

Nota: el servidor Minecraft requiere que el usuario acepte la EULA de Minecraft cambiando `server\eula.txt` a `eula=true`.

## Assets para stream

`stream-assets\icons` trae iconos PNG de acciones. La mayoria son `192x192`, buenos para botones y tarjetas chicas.

`stream-assets\weapons\slot_colored` trae armas coloreadas sacadas del slot/inventario del mod:

- `original_png`: fuente original, normalmente `64x64`.
- `x4_256_png`: version pixel art expandida 4x.
- `banner_512_png`: version centrada en lienzo transparente `512x512`.
- `banner_512_webp`: lo mismo en WebP.

`stream-assets\banners` trae banners grandes:

- `1920x1080`
- `1920x640`
- `1280x720`
- `1200x630`

## Documentacion interna

- `docs\ARQUITECTURA.md`: mapa tecnico del proyecto, EventBus, RCON, manifest y runtime.
- `docs\REGLAS_COMANDOS_MC.md`: plan para reglas con comandos Minecraft, armas propias, enemigos y seguridad.
- `docs\ERRORES_COMUNES.md`: fallos ya vistos en instalacion/publicacion y como revisarlos.

## Estado actual

Este proyecto queda listo como prototipo admin/local con el modpack reconstruido: fuente, instalacion local, perfil Minecraft y servidor tienen 228 `.jar`.

Antes de entregarlo como juego publico hay que validar licencias/permisos de redistribucion de los mods, probar el servidor modded real con jugadores y ejecutar:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\usuario\Documents\App\scripts\validar_paquete_juego.ps1 -Path "C:\Users\usuario\Music\JUEGOS TIKTOK\Cursed Walking-V3.2.3 - Release\Cursed Walking MOD Live"
```
