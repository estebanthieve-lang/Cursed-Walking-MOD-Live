# Cursed Walking MOD Live

Proyecto local/admin para conectar Cursed Walking V3.2.3 a TikTok Live Games.

## Como se usa en la app

1. Abrir el launcher local con `C:\Users\usuario\Documents\App\apps\launcher\ABRIR_LAUNCHER_LOCAL.cmd`.
2. Buscar `Cursed Walking MOD Live` en el catalogo admin.
3. Instalar desde la fuente local.
4. Revisar `server\eula.txt`; solo cambiar a `eula=true` si aceptas la EULA de Minecraft.
5. Usar `Jugar ahora`.

El EventBus responde en:

```txt
http://127.0.0.1:9060/manifest
POST http://127.0.0.1:9060/event
```

## Armas y comandos

Las acciones viven en `game-manifest.json`.

Los comandos reales viven en:

```txt
config\live_actions.json
```

Para cambiar el arma de `give_configured_weapon`, edita:

```json
"give_configured_weapon": {
  "defaultWeaponKey": "ak47",
  "allowPayloadWeaponKey": true
}
```

Y usa una clave de `weapons`, por ejemplo `m4a1`, `mp5`, `m249`, `m107`, `shotgun`, `minigun`, `rpg7` o `sfms_m4a5`.

## Estado

Esto es una base conectable para pruebas admin/local. El export original de CurseForge trae `manifest.json` con IDs de mods; el proyecto ahora reconstruye `game\mods` con `scripts\descargar_mods_curseforge.ps1` y ya quedo con 228 `.jar`.

Antes de publicarlo a usuarios hay que revisar permisos/licencias de redistribucion y hacer prueba real de acciones dentro de Minecraft.
