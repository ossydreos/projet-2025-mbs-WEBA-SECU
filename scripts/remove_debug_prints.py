from __future__ import annotations

from pathlib import Path


def remove_print_statements(text: str) -> str:
    lines = text.splitlines(keepends=True)
    result: list[str] = []
    skipping = False
    balance = 0

    for line in lines:
        stripped = line.lstrip()
        if not skipping and stripped.startswith("print("):
            skipping = True
            balance = stripped.count("(") - stripped.count(")")
            if stripped.rstrip().endswith(";") and balance <= 0:
                skipping = False
            continue

        if skipping:
            balance += line.count("(") - line.count(")")
            if line.rstrip().endswith(";") and balance <= 0:
                skipping = False
            continue

        result.append(line)

    return "".join(result)


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    lib_dir = project_root / "lib"

    for path in lib_dir.rglob("*.dart"):
        original_text = path.read_text(encoding="utf-8")
        updated_text = remove_print_statements(original_text)
        if updated_text != original_text:
            path.write_text(updated_text, encoding="utf-8")


if __name__ == "__main__":
    main()
