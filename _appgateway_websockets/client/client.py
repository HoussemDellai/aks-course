"""WebSocket client that sends messages and prints server responses."""

import asyncio
import os
import websockets
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s")
log = logging.getLogger(__name__)

SERVER_URI = os.environ.get("SERVER_URI", "ws://localhost:8765")


async def main() -> None:
    async with websockets.connect(SERVER_URI) as ws:
        log.info("Connected to %s", SERVER_URI)

        i = 1
        while True:
            message = f"Hello #{i}"
            await ws.send(message)
            log.info("Sent: %s", message)

            response = await ws.recv()
            log.info("Received: %s", response)

            await asyncio.sleep(1)
            i += 1

        # log.info("Done — closing connection.")


if __name__ == "__main__":
    asyncio.run(main())
