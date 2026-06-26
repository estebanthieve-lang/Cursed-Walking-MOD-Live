# Arquitectura de Cursed Walking MOD Live

Este proyecto conecta el modpack Cursed Walking con TikTok Live Games usando una app launcher local, un EventBus HTTP y comandos RCON hacia Minecraft.

## Piezas principales

- `game-manifest.json`
  Catalogo publico del juego. Define nombre, descripcion, puerto del EventBus, acciones visibles y rutas de imagen para la app.

- `config/live_actions.json`
  Configuracion ejecutable. Define RCON, jugador objetivo, armas disponibles y comandos reales que se mandan a Minecraft.

- `runtime/event_bus.py`
  Servidor HTTP local. Expone `/manifest`, `/actions`, `/health` y recibe eventos en `/event`.

- `runtime/game_adapter.py`
  Convierte una accion en comandos Minecraft. Valida `actionId`, resuelve `{player}`, `{viewer}`, `{quantity}`, arma seleccionada y manda RCON o cola fallback.

- `assets/acciones_png`
  Iconos que la app usa para acciones. Si existe `assets/acciones_png/<actionId>.png`, la app puede mostrarlo automaticamente.

- `stream-assets`
  Assets para stream, banners, catalogos y previews. No todos son usados por la app directamente.

- `scripts`
  Automatizacion local: preparar cliente, preparar servidor, iniciar EventBus, iniciar servidor y validar el paquete.

## Flujo al jugar

1. La app instala o actualiza el paquete en `%LOCALAPPDATA%/TikTokLiveGames/games/cursed-walking-mod-live`.
2. `scripts/preparar_cliente.ps1` sincroniza el perfil de Minecraft.
3. `scripts/iniciar_servidor.ps1` levanta el server local de Minecraft.
4. `scripts/iniciar_event_bus.ps1` levanta el EventBus en `127.0.0.1:9060`.
5. La app lee `GET /manifest` y muestra acciones/reglas.
6. TikTok Live Games manda un evento a `POST /event`.
7. `game_adapter.py` transforma el evento en comandos y los manda por RCON.

## Contratos importantes

- El `id` de cada accion en `game-manifest.json` debe existir tambien en `config/live_actions.json`.
- Las acciones de arma usan `weaponKey`.
- El arma real se define en `config/live_actions.json` bajo `weapons`.
- Los comandos pueden usar placeholders: `{player}`, `{viewer}`, `{quantity}`.
- El jugador objetivo se valida contra `target.allowedSelectors`.

## Como agregar un arma

1. Agregar la entrada en `config/live_actions.json` dentro de `weapons`.
2. Agregar una accion directa en `config/live_actions.json`, por ejemplo:

```json
"give_weapon_mi_arma": {
  "weaponKey": "mi_arma"
}
```

3. Agregar la accion visible en `game-manifest.json`.
4. Poner icono en `assets/acciones_png/give_weapon_mi_arma.png`.
5. Si quieres banner, poner version limpia en `stream-assets/weapons`.

## Como agregar enemigos

El camino recomendado es crear un bloque `entities` o `enemies` en `config/live_actions.json` con claves estables, por ejemplo:

```json
"enemies": {
  "fast_zombie": {
    "label": "Zombie rapido",
    "summon": "minecraft:zombie",
    "effects": [
      "effect give @e[type=minecraft:zombie,distance=..16,limit=8,sort=nearest] minecraft:speed 20 1 true"
    ]
  }
}
```

Despues se declara una accion `spawn_enemy_fast_zombie` en manifest/config y se le asigna icono.

## Para refactor visual futuro

La UI puede cambiar fuerte mientras respete estos contratos:

- Leer acciones desde `game-manifest.json` o `/manifest`.
- Mantener `actionId` estable.
- Mandar eventos a `/event` con `actionId`, `viewer`, `params` y opcionalmente `quantity`.
- No asumir que todas las acciones son armas; hay comandos, spawns, clima, tiempo y utilidades.
- No tocar `runtime/game_adapter.py` sin revisar el formato de eventos y el sistema de RCON.
