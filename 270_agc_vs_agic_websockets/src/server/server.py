"""WebSocket echo server using the `websockets` library."""

import asyncio
import os
from http import HTTPStatus
import websockets
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s")
log = logging.getLogger(__name__)

WEBSOCKET_PROCESSING_DURATION = int(os.environ.get("WEBSOCKET_PROCESSING_DURATION", "10"))

CONNECTIONS: set[websockets.WebSocketServerProtocol] = set()


def process_request(path: str, request_headers):
    if path == "/health":
        log.info("Received health check request from %s", request_headers.get("User-Agent", "unknown"))
        body = b"OK\n"
        return (
            HTTPStatus.OK,
            [
                ("Content-Type", "text/plain"),
                ("Content-Length", str(len(body))),
            ],
            body,
        )
    return None


async def handler(websocket: websockets.WebSocketServerProtocol) -> None:
    """Handle a single WebSocket connection."""
    remote = websocket.remote_address
    log.info("Client connected: %s", remote)
    CONNECTIONS.add(websocket)
    
    try:
        async for message in websocket:
            log.info("Received from %s: %s", remote, message)
            # hold the connection for the specified duration to demonstrate that it stays open
            await asyncio.sleep(WEBSOCKET_PROCESSING_DURATION)
            # Echo the message back
            await websocket.send(f"echo from server {websocket.local_address} : {message}")
    except websockets.ConnectionClosed as exc:
        log.info("Connection closed (%s): %s", remote, exc)
    finally:
        CONNECTIONS.discard(websocket)
        log.info("Client disconnected: %s", remote)


async def main() -> None:
    host = "0.0.0.0"
    port = 8765
    async with websockets.serve(handler, host, port, process_request=process_request):
        log.info("WebSocket server listening on ws://%s:%s", host, port)
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    asyncio.run(main())
