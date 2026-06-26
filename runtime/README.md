# Runtime Minecraft

Aqui va el EventBus del juego y el adaptador.

Contrato minimo:

- `GET /manifest` devuelve el manifest instalado.
- `POST /event` recibe `{ "action": "...", "eventId": "...", "payload": {} }`.
- Deduplica por `eventId`.
- Encola acciones lentas.
- Escribe logs en `logs`.
- No abre CMD visible al usuario final cuando lo ejecuta la app.

Pendiente obligatorio para cada juego:

- puente real hacia Minecraft.

No marcar como listo si el adaptador solo escribe archivos que Minecraft no consume.
