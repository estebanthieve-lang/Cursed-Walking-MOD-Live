# Plan para reglas con comandos Minecraft

Objetivo: permitir que una regla de TikTok Live Games ejecute acciones del catalogo o comandos Minecraft controlados, sin tener que editar codigo cada vez.

## Modelo mental

Una regla deberia tener:

- Trigger: regalo, like, follow, comentario/comando de chat o evento manual.
- Costo: monedas, regalo especifico, cantidad de likes o cooldown.
- Accion: accion del catalogo o comando Minecraft.
- Parametros: jugador, cantidad, arma, enemigo, duracion, radio, etc.

Ejemplos:

- Regalo barato -> `give_weapon_ak47`.
- Regalo caro -> `give_weapon_minigun`.
- Comentario `!horda` -> `spawn_zombie_wave`.
- Regla admin -> comando Minecraft personalizado.

## Lo que ya existe

El runtime ya soporta:

- Acciones declaradas en `game-manifest.json`.
- Configuracion real en `config/live_actions.json`.
- Comandos Minecraft en `commands`.
- Armas por `weaponKey`.
- Placeholders: `{player}`, `{viewer}`, `{quantity}`.
- RCON directo con fallback a `data/minecraft_commands.jsonl`.

Ejemplo actual:

```json
"give_weapon_ak47": {
  "weaponKey": "ak47"
}
```

Ejemplo de comandos:

```json
"spawn_zombie_wave": {
  "repeat": 5,
  "commands": [
    "execute at {player} run summon minecraft:zombie ~2 ~ ~"
  ]
}
```

## Siguiente paso recomendado

Agregar una accion generica segura:

```json
{
  "id": "run_minecraft_command",
  "label": "Ejecutar comando MC",
  "description": "Ejecuta un comando Minecraft permitido desde una regla admin.",
  "type": "admin_action",
  "params": {
    "command": {
      "type": "text",
      "placeholder": "say Hola {viewer}"
    }
  }
}
```

Y en `config/live_actions.json`:

```json
"run_minecraft_command": {
  "allowPayloadCommand": true,
  "adminOnly": true
}
```

Luego `game_adapter.py` debe validar el comando antes de mandarlo por RCON.

## Seguridad necesaria

No conviene dejar comandos totalmente libres para reglas publicas. Minimo:

- Solo admin local puede crear reglas con comando libre.
- Bloquear comandos peligrosos por defecto: `op`, `deop`, `stop`, `ban`, `pardon`, `whitelist`, `save-off`, `reload`, `kick`.
- Limitar largo del comando.
- Permitir placeholders controlados.
- Validar selector contra `target.allowedSelectors`.
- Mostrar vista previa del comando final antes de guardar.

## UI futura

En la pantalla de reglas conviene tener:

- Selector de trigger: regalo, likes, follow, comentario, comando de chat.
- Selector de accion: armas, enemigos, utilidades, comando MC.
- Campo de costo o regalo requerido.
- Campo de target: `@p`, `@a`, usuario fijo o selector permitido.
- Campos dinamicos segun accion.
- Preview visual: regalo + accion + icono + comando resultante.

## Agregar armas propias

Para un arma nueva de TACZ u otro mod:

1. Buscar su `GunId`, por ejemplo `modid:arma`.
2. Agregarla en `config/live_actions.json` bajo `weapons`.
3. Crear accion directa o usar `give_configured_weapon`.
4. Agregar icono a `assets/acciones_png`.
5. Agregar imagen de banner a `stream-assets/weapons`.

## Agregar enemigos propios

Para un enemigo o mob nuevo:

1. Buscar su entity id, por ejemplo `modid:enemigo`.
2. Crear accion con comando `summon`.
3. Agregar efectos o equipo si aplica.
4. Agregar icono del enemigo a `assets/acciones_png`.
5. Crear regla con costo/cooldown para no saturar el servidor.

## Recomendacion de trabajo

Codex deberia mantener el contrato tecnico, runtime, seguridad y datos.
Claude Code puede redisenar la UI encima si respeta `manifest`, `actionId`, `params` y `/event`.
