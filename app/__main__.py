import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import anyio
import logfire
from rich.console import Console

console = Console()
logfire.configure(send_to_logfire=False)


class _HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"ok\n")

    def log_message(self, fmt: str, *args: object) -> None:
        pass


async def main_async() -> None:
    with logfire.span("app-startup"):
        console.print("[bold green]Hello from app![/]")
        console.print("[dim]multicluster: kubectl front=perturabo (nix), back=angron (std n2c)[/]")
    port = int(os.environ.get("PORT", "8000"))
    server = ThreadingHTTPServer(("0.0.0.0", port), _HealthHandler)
    await anyio.to_thread.run_sync(server.serve_forever)


def main() -> None:
    anyio.run(main_async)


if __name__ == "__main__":
    main()
