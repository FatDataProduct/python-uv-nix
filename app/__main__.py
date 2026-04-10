import anyio
import logfire
from rich.console import Console

console = Console()
logfire.configure(send_to_logfire=False)


async def main_async() -> None:
    with logfire.span("app-startup"):
        console.print("[bold green]Hello from app![/]")
        console.print("[dim]nix-snapshotter pilot on perturabo[/]")


def main() -> None:
    anyio.run(main_async)


if __name__ == "__main__":
    main()
