import anyio
from rich.console import Console

console = Console()


async def main_async() -> None:
    console.print("[bold green]Hello from app![/]")


def main() -> None:
    anyio.run(main_async)


if __name__ == "__main__":
    main()
