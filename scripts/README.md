# Scripts Minecraft

Aqui van scripts de preparacion/validacion usados por la app o por desarrollo.

## Indice

- `preparar_cliente.ps1`: crea/sincroniza la instancia aislada de Minecraft.
- `preparar_servidor.ps1`: prepara el servidor Forge local declarado en `config\minecraft_server.json`.
- `sincronizar_mod.ps1`: copia el mod bridge a cliente y servidor.
- `iniciar_event_bus.ps1`: levanta el EventBus local oculto.
- `iniciar_servidor.ps1`: levanta el servidor local oculto.
- `actualizar_juego.ps1`: aplica una version nueva respetando `protectedPaths` y `updatablePaths`.
- `validar_juego.ps1`: revisa que la plantilla no quede a medio camino.

Reglas:

- No incluir tokens.
- No incluir rutas personales.
- No borrar perfiles globales.
- No tocar mods globales.
- No abrir `localhost:5177`.
- No mostrar consolas al usuario final cuando la app ejecute el flujo.

Si un script existe solo para desarrollo, no debe ir al release limpio salvo que sea necesario.
