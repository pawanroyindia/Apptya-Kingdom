#!/usr/bin/env python3
"""Fast repository preflight; this does not compile Unity C# or build an APK."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = [
    "UnityProject/Assets/Scripts/ApptyaGameState.cs",
    "UnityProject/Assets/Scripts/ProceduralKingdomBootstrap.cs",
    "UnityProject/Assets/Scripts/ApptyaRuntimeHud.cs",
    "UnityProject/Assets/Scripts/ApptyaCameraController.cs",
    "UnityProject/Assets/Scripts/ApptyaBuildingVisuals.cs",
    "UnityProject/Assets/Scripts/ApptyaBuildingTap.cs",
    "UnityProject/Assets/Editor/ApptyaProjectSetup.cs",
    "UnityProject/Assets/Editor/ApptyaProjectValidator.cs",
    "UnityProject/Packages/manifest.json",
    "UnityProject/ProjectSettings/ProjectVersion.txt",
]
PAIRS = {"(": ")", "{": "}", "[": "]"}


def delimiters(path: Path) -> list[str]:
    """Check balanced C# delimiters while ignoring comments and string/char literals."""
    source = path.read_text(encoding="utf-8")
    stack: list[tuple[str, int]] = []
    errors: list[str] = []
    i, line, state = 0, 1, "code"
    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""
        if ch == "\n":
            line += 1
        if state == "line_comment":
            if ch == "\n":
                state = "code"
        elif state == "block_comment":
            if ch == "*" and nxt == "/":
                state = "code"
                i += 1
        elif state in ("string", "char"):
            if ch == "\\":
                i += 1
            elif (state == "string" and ch == '"') or (state == "char" and ch == "'"):
                state = "code"
        else:
            if ch == "/" and nxt == "/":
                state = "line_comment"
                i += 1
            elif ch == "/" and nxt == "*":
                state = "block_comment"
                i += 1
            elif ch == '"':
                state = "string"
            elif ch == "'":
                state = "char"
            elif ch in PAIRS:
                stack.append((ch, line))
            elif ch in PAIRS.values():
                if not stack or PAIRS[stack[-1][0]] != ch:
                    errors.append(f"{path.relative_to(ROOT)}:{line}: unmatched {ch}")
                else:
                    stack.pop()
        i += 1
    if state == "block_comment":
        errors.append(f"{path.relative_to(ROOT)}: unterminated block comment")
    if state in ("string", "char"):
        errors.append(f"{path.relative_to(ROOT)}: unterminated string/char literal")
    for opener, opener_line in stack:
        errors.append(f"{path.relative_to(ROOT)}:{opener_line}: unclosed {opener}")
    return errors


def main() -> int:
    errors: list[str] = []
    for relative in REQUIRED:
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"Missing required file: {relative}")
    manifest_path = ROOT / "UnityProject/Packages/manifest.json"
    if manifest_path.is_file():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            dependencies = manifest.get("dependencies", {})
            if "com.unity.render-pipelines.universal" not in dependencies:
                errors.append("manifest.json: Universal Render Pipeline dependency is missing")
            if "com.unity.ugui" not in dependencies:
                errors.append("manifest.json: uGUI dependency is missing")
        except (json.JSONDecodeError, AttributeError) as exc:
            errors.append(f"manifest.json: invalid dependency JSON ({exc})")
    version_path = ROOT / "UnityProject/ProjectSettings/ProjectVersion.txt"
    if version_path.is_file() and "m_EditorVersion: 6000.0.46f1" not in version_path.read_text(encoding="utf-8"):
        errors.append("ProjectVersion.txt: expected Unity 6000.0.46f1")
    for path in sorted((ROOT / "UnityProject/Assets").rglob("*.cs")):
        errors.extend(delimiters(path))
    if errors:
        print("Apptya Kingdom source preflight FAILED:")
        print("\n".join(f"- {error}" for error in errors))
        return 1
    print(f"Apptya Kingdom source preflight passed: {len(REQUIRED)} required files, valid package manifest, expected Unity version, and balanced C# delimiters.")
    print("Note: this is a static check only; it does not compile Unity scripts, run gameplay, or build an APK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
