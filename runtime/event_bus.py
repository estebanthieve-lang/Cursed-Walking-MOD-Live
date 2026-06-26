from __future__ import annotations

import json
import threading
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

import game_adapter


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "game-manifest.json"
CONFIG_PATH = ROOT / "game.config.json"
INBOX_PATH = ROOT / "data" / "events_inbox.jsonl"
SEEN_EVENT_IDS: set[str] = set()
SEEN_EVENT_ORDER: deque[str] = deque()
SEEN_EVENT_LOCK = threading.Lock()
MAX_SEEN_EVENTS = 5000


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def load_manifest() -> dict:
    manifest = load_json(MANIFEST_PATH)
    if not manifest.get("gameId"):
        raise ValueError("manifest sin gameId")
    if not manifest.get("actions"):
        raise ValueError("manifest sin actions[]")
    return manifest


def load_config() -> dict:
    return load_json(CONFIG_PATH)


def action_ids(manifest: dict) -> set[str]:
    return {str(action.get("id", "")).strip() for action in manifest.get("actions", [])}


def reserve_event(event_id: str) -> bool:
    if not event_id:
        return True
    with SEEN_EVENT_LOCK:
        if event_id in SEEN_EVENT_IDS:
            return False
        SEEN_EVENT_IDS.add(event_id)
        SEEN_EVENT_ORDER.append(event_id)
        while len(SEEN_EVENT_ORDER) > MAX_SEEN_EVENTS:
            SEEN_EVENT_IDS.discard(SEEN_EVENT_ORDER.popleft())
        return True


def release_event(event_id: str) -> None:
    if not event_id:
        return
    with SEEN_EVENT_LOCK:
        SEEN_EVENT_IDS.discard(event_id)


class Handler(BaseHTTPRequestHandler):
    server_version = "CursedWalkingMODLive/0.1"

    def send_json(self, status: int, body: dict) -> None:
        raw = json.dumps(body, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(raw)

    def do_OPTIONS(self) -> None:
        self.send_json(204, {})

    def do_GET(self) -> None:
        try:
            manifest = load_manifest()
            path = urlparse(self.path).path
            if path in ("/manifest", "/game-manifest.json"):
                self.send_json(200, manifest)
                return
            if path == "/actions":
                self.send_json(200, {"gameId": manifest["gameId"], "actions": manifest["actions"]})
                return
            if path == "/health":
                self.send_json(200, {"ok": True, "gameId": manifest["gameId"]})
                return
            self.send_json(404, {"ok": False, "error": "ruta no encontrada"})
        except Exception as error:
            self.send_json(500, {"ok": False, "error": str(error)})

    def do_POST(self) -> None:
        try:
            manifest = load_manifest()
            config = load_config()
            event_path = str(manifest.get("eventBus", {}).get("path", "/event"))
            path = urlparse(self.path).path
            if path != event_path:
                self.send_json(404, {"ok": False, "error": "ruta no encontrada"})
                return

            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            action_id = str(payload.get("action") or payload.get("actionId") or payload.get("id") or "").strip()
            event_id = str(payload.get("eventId", "")).strip()
            if action_id not in action_ids(manifest):
                self.send_json(404, {"ok": False, "error": f"accion no declarada: {action_id}"})
                return
            if not reserve_event(event_id):
                self.send_json(200, {"ok": True, "duplicate": True, "eventId": event_id, "executed": False})
                return

            try:
                INBOX_PATH.parent.mkdir(parents=True, exist_ok=True)
                with INBOX_PATH.open("a", encoding="utf-8") as handle:
                    handle.write(json.dumps(payload, ensure_ascii=False) + "\n")
                result = game_adapter.handle_event(payload, ROOT, manifest, config)
            except Exception:
                release_event(event_id)
                raise
            self.send_json(200, {"ok": True, "executed": action_id, "result": result})
        except Exception as error:
            self.send_json(500, {"ok": False, "error": str(error)})

    def log_message(self, fmt: str, *args) -> None:
        log_dir = ROOT / "logs" / "runtime"
        log_dir.mkdir(parents=True, exist_ok=True)
        with (log_dir / "event-bus-http.log").open("a", encoding="utf-8") as handle:
            handle.write((fmt % args) + "\n")


def main() -> None:
    manifest = load_manifest()
    event_bus = manifest.get("eventBus", {})
    host = str(event_bus.get("host", "127.0.0.1"))
    port = int(event_bus.get("port", 9021))
    print(f"EventBus {manifest['gameId']} listening on http://{host}:{port}")
    print(f"Manifest: http://{host}:{port}/manifest")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
