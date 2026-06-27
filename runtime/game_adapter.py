from __future__ import annotations

import json
import re
import socket
import struct
import time
from pathlib import Path
from typing import Any


USERNAME_RE = re.compile(r"^[A-Za-z0-9_]{1,16}$")
SAFE_VIEWER_RE = re.compile(r"[^A-Za-z0-9_ .-]")
UNSAFE_COMMAND_RE = re.compile(r"[;|`$<>]")
BLOCKED_COMMANDS = {"stop", "op", "deop", "ban", "ban-ip", "pardon", "pardon-ip", "whitelist", "save-off"}
SILENT_SERVER_COMMANDS = (
    "gamerule sendCommandFeedback false",
    "gamerule commandBlockOutput false",
    "gamerule logAdminCommands false",
    "gamerule announceAdvancements false",
)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def deep_merge(base: dict[str, Any], overlay: dict[str, Any]) -> dict[str, Any]:
    result = dict(base)
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def load_action_config(root: Path, config: dict[str, Any]) -> dict[str, Any]:
    rel = str(config.get("actionConfig") or "config/live_actions.json")
    base_path = root / rel
    live_config = load_json(base_path)
    local_path = base_path.with_name("live_actions.local.json")
    if local_path.exists():
        live_config = deep_merge(live_config, load_json(local_path))
    return live_config


def packet(request_id: int, request_type: int, payload: str) -> bytes:
    encoded = payload.encode("utf-8")
    body = struct.pack("<ii", request_id, request_type) + encoded + b"\x00\x00"
    return struct.pack("<i", len(body)) + body


def recv_exact(sock: socket.socket, size: int) -> bytes:
    chunks: list[bytes] = []
    remaining = size
    while remaining > 0:
        chunk = sock.recv(remaining)
        if not chunk:
            raise ConnectionError("RCON connection closed")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)


def read_packet(sock: socket.socket) -> tuple[int, int, str]:
    raw_size = recv_exact(sock, 4)
    size = struct.unpack("<i", raw_size)[0]
    body = recv_exact(sock, size)
    request_id, response_type = struct.unpack("<ii", body[:8])
    payload = body[8:-2].decode("utf-8", errors="replace")
    return request_id, response_type, payload


class RconClient:
    def __init__(self, host: str, port: int, password: str, timeout: float) -> None:
        self.host = host
        self.port = port
        self.password = password
        self.timeout = timeout
        self.sock: socket.socket | None = None
        self.next_id = 100

    def __enter__(self) -> "RconClient":
        self.sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self.sock.settimeout(self.timeout)
        self._send(3, self.password)
        request_id, _, _ = read_packet(self.sock)
        if request_id == -1:
            raise PermissionError("RCON auth failed")
        return self

    def __exit__(self, *_args: object) -> None:
        if self.sock:
            self.sock.close()

    def _send(self, request_type: int, payload: str) -> int:
        if not self.sock:
            raise ConnectionError("RCON socket is not connected")
        self.next_id += 1
        request_id = self.next_id
        self.sock.sendall(packet(request_id, request_type, payload))
        return request_id

    def command(self, command: str) -> str:
        if not self.sock:
            raise ConnectionError("RCON socket is not connected")
        request_id = self._send(2, command)
        response_id, _, response = read_packet(self.sock)
        if response_id not in (request_id, 0):
            return response
        return response


def clean_viewer(value: Any) -> str:
    raw = str(value or "").strip()[:48]
    return SAFE_VIEWER_RE.sub("", raw) or "viewer"


def resolve_target(payload: dict[str, Any], live_config: dict[str, Any]) -> str:
    params = payload.get("params") if isinstance(payload.get("params"), dict) else {}
    target_config = live_config.get("target") if isinstance(live_config.get("target"), dict) else {}
    default_player = str(target_config.get("defaultPlayer") or "@p")
    candidate = (
        params.get("minecraftPlayer")
        or params.get("player")
        or params.get("target")
        or payload.get("minecraftPlayer")
        or payload.get("player")
        or payload.get("target")
        or default_player
    )
    value = str(candidate).strip()
    allowed_selectors = set(target_config.get("allowedSelectors") or ["@p", "@a", "@r", "@s"])
    if value.startswith("@"):
        if bool(target_config.get("allowSelectors", True)) and value in allowed_selectors:
            return value
        return default_player
    if USERNAME_RE.match(value):
        return value
    return default_player


def resolve_quantity(payload: dict[str, Any], live_config: dict[str, Any]) -> int:
    params = payload.get("params") if isinstance(payload.get("params"), dict) else {}
    raw = (
        params.get("quantity")
        or payload.get("actionQuantity")
        or payload.get("quantity")
        or payload.get("repeatCount")
        or 1
    )
    try:
        quantity = int(raw)
    except (TypeError, ValueError):
        quantity = 1
    target_config = live_config.get("target") if isinstance(live_config.get("target"), dict) else {}
    max_quantity = int(target_config.get("maxQuantity") or 25)
    return max(1, min(quantity, max_quantity))


def resolve_weapon_key(
    payload: dict[str, Any],
    action_config: dict[str, Any],
    weapons: dict[str, Any],
) -> str | None:
    key = action_config.get("weaponKey") or action_config.get("defaultWeaponKey")
    if action_config.get("allowPayloadWeaponKey"):
        params = payload.get("params") if isinstance(payload.get("params"), dict) else {}
        key = params.get("weaponKey") or payload.get("weaponKey") or key
    if key is None:
        return None
    key = str(key).strip()
    if key not in weapons:
        raise ValueError(f"weaponKey no permitido: {key}")
    return key


def weapon_commands(player: str, weapon: dict[str, Any], quantity: int) -> list[str]:
    gun_id = str(weapon.get("gunId") or "").strip()
    ammo_id = str(weapon.get("ammoId") or "").strip()
    ammo_amount = int(weapon.get("ammoAmount") or 64)
    amount = max(1, int(quantity or 1))
    if not gun_id:
        raise ValueError("weapon sin gunId")
    commands = [f'give {player} tacz:modern_kinetic_gun{{GunId:"{gun_id}"}} {amount}']
    if ammo_id:
        commands.append(f'give {player} tacz:ammo{{AmmoId:"{ammo_id}"}} {ammo_amount * amount}')
    return commands


def render_command(command: str, context: dict[str, str]) -> str:
    rendered = command
    for key, value in context.items():
        rendered = rendered.replace("{" + key + "}", value)
    return rendered.strip().lstrip("/")


def validate_manual_command(command: str) -> str:
    rendered = command.strip().lstrip("/")
    if not rendered:
        raise ValueError("comando manual vacio")
    if len(rendered) > 1000:
        raise ValueError("comando manual demasiado largo")
    if UNSAFE_COMMAND_RE.search(rendered):
        raise ValueError("comando manual contiene caracteres no permitidos")
    first_token = rendered.split(maxsplit=1)[0].lower()
    if first_token in BLOCKED_COMMANDS:
        raise ValueError(f"comando manual bloqueado: {first_token}")
    return rendered


def expand_manual_commands(
    payload: dict[str, Any],
    live_config: dict[str, Any],
) -> list[str]:
    player = resolve_target(payload, live_config)
    viewer = clean_viewer(payload.get("viewer") or payload.get("username") or payload.get("nickname"))
    source = payload.get("source") if isinstance(payload.get("source"), dict) else {}
    quantity = resolve_quantity(payload, live_config)
    context = {
        "player": player,
        "playername": player,
        "viewer": viewer,
        "viewerName": viewer,
        "quantity": str(quantity),
        "giftName": str(source.get("giftName") or payload.get("giftName") or ""),
        "giftId": str(source.get("giftId") or payload.get("giftId") or ""),
        "repeatCount": str(source.get("repeatCount") or payload.get("repeatCount") or 1),
    }

    commands: list[str] = []
    primary = str(payload.get("manualCommand") or payload.get("command") or "")
    if primary.strip():
        commands.append(validate_manual_command(render_command(primary, context)))

    sequence = payload.get("commandSequence")
    if isinstance(sequence, list):
        for step in sequence[:20]:
            if not isinstance(step, dict):
                continue
            try:
                delay_ms = int(step.get("delayMs") or step.get("delay_ms") or 0)
            except (TypeError, ValueError):
                delay_ms = 0
            if delay_ms:
                raise ValueError("commandSequence.delayMs aun no esta soportado por este EventBus")
            try:
                repeat = max(1, min(100, int(step.get("repeat") or 1)))
            except (TypeError, ValueError):
                repeat = 1
            command = str(step.get("command") or "")
            rendered = validate_manual_command(render_command(command, context))
            commands.extend([rendered] * repeat)

    if not commands:
        raise ValueError("accion manual sin comandos")
    return commands


def expand_commands(
    payload: dict[str, Any],
    action_id: str,
    live_config: dict[str, Any],
) -> list[str]:
    actions = live_config.get("actions") if isinstance(live_config.get("actions"), dict) else {}

    weapons = live_config.get("weapons") if isinstance(live_config.get("weapons"), dict) else {}
    player = resolve_target(payload, live_config)
    viewer = clean_viewer(payload.get("viewer") or payload.get("username") or payload.get("nickname"))
    quantity = resolve_quantity(payload, live_config)

    if action_id == "minecraft_manual_command":
        return expand_manual_commands(payload, live_config)

    action_config = actions.get(action_id)
    if not isinstance(action_config, dict):
        raise ValueError(f"accion sin config/live_actions.json: {action_id}")

    repeat = max(1, int(action_config.get("repeat") or 1)) * quantity

    commands: list[str] = []
    weapon_key = resolve_weapon_key(payload, action_config, weapons)
    if weapon_key:
        weapon = weapons[weapon_key]
        weapon_context = {
            "player": player,
            "viewer": viewer,
            "quantity": str(quantity),
            "weaponKey": weapon_key,
            "weaponGunId": str(weapon.get("gunId") or ""),
            "weaponAmmoId": str(weapon.get("ammoId") or ""),
        }
        commands.extend(render_command(command, weapon_context) for command in weapon_commands(player, weapon, quantity))

    configured_commands = action_config.get("commands") or []
    if not isinstance(configured_commands, list):
        raise ValueError(f"commands debe ser lista para {action_id}")

    context = {
        "player": player,
        "viewer": viewer,
        "quantity": str(quantity),
    }
    for _ in range(repeat):
        for command in configured_commands:
            rendered = render_command(str(command), context)
            if rendered:
                commands.append(rendered)

    if not commands:
        raise ValueError(f"accion sin comandos: {action_id}")
    return commands


def queue_commands(
    root: Path,
    queue_rel: str,
    payload: dict[str, Any],
    commands: list[str],
    note: str,
) -> Path:
    queue_path = root / queue_rel
    queue_path.parent.mkdir(parents=True, exist_ok=True)
    record = {
        "ts": time.time(),
        "action": payload.get("action") or payload.get("actionId") or payload.get("id"),
        "payload": payload,
        "commands": commands,
        "note": note,
        "source": "cursed-walking-mod-live",
    }
    with queue_path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")
    return queue_path


def send_rcon(live_config: dict[str, Any], commands: list[str]) -> list[dict[str, str]]:
    rcon = live_config.get("rcon") if isinstance(live_config.get("rcon"), dict) else {}
    if not rcon.get("enabled", True):
        raise ConnectionError("RCON desactivado en config/live_actions.json")
    host = str(rcon.get("host") or "127.0.0.1")
    port = int(rcon.get("port") or 25582)
    password = str(rcon.get("password") or "")
    timeout = float(rcon.get("timeoutSeconds") or 3)
    if not password:
        raise ValueError("RCON sin password")
    responses: list[dict[str, str]] = []
    with RconClient(host, port, password, timeout) as client:
        if bool(rcon.get("silenceMinecraftChat", True)):
            for command in SILENT_SERVER_COMMANDS:
                try:
                    client.command(command)
                except Exception:
                    pass
        for command in commands:
            responses.append({"command": command, "response": client.command(command)})
    return responses


def summarize_responses(responses: list[dict[str, str]], max_items: int = 8) -> dict[str, Any]:
    if len(responses) <= max_items:
        return {"responses": responses}
    return {
        "responses": responses[:max_items],
        "responsesTruncated": len(responses) - max_items,
        "responseCount": len(responses),
    }


def handle_event(payload: dict[str, Any], root: Path, manifest: dict, config: dict) -> dict:
    action = payload.get("action") or payload.get("actionId") or payload.get("id")
    if not action:
        raise ValueError("event payload missing action")
    action_id = str(action)

    actions = {item.get("id"): item for item in manifest.get("actions", [])}
    if action_id not in actions:
        raise ValueError(f"unknown action: {action_id}")

    live_config = load_action_config(root, config)
    commands = expand_commands(payload, action_id, live_config)
    rcon = live_config.get("rcon") if isinstance(live_config.get("rcon"), dict) else {}
    queue_rel = str(rcon.get("queue") or config.get("minecraft", {}).get("bridgeQueue") or "data/minecraft_commands.jsonl")

    try:
        responses = send_rcon(live_config, commands)
        queue_path = queue_commands(root, queue_rel, payload, commands, "sent-to-rcon")
        return {
            "rconSent": True,
            "queued": False,
            "queue": str(queue_path),
            "commands": len(commands),
            **summarize_responses(responses),
        }
    except Exception as error:
        if not bool(rcon.get("fallbackToQueue", True)):
            raise
        queue_path = queue_commands(root, queue_rel, payload, commands, f"rcon-fallback: {error}")
        return {
            "rconSent": False,
            "queued": True,
            "queue": str(queue_path),
            "commands": len(commands),
            "error": str(error),
            "note": "RCON no respondio. Inicia el servidor, acepta eula.txt y revisa server.properties.",
        }
