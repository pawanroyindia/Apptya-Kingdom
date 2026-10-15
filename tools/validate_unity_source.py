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



def gameplay_invariants() -> list[str]:
    """Guard critical gameplay rules against accidental source regressions."""
    errors: list[str] = []
    state_path = ROOT / "UnityProject/Assets/Scripts/ApptyaGameState.cs"
    if not state_path.is_file():
        return errors
    source = state_path.read_text(encoding="utf-8")

    battle_start = source.find("public string AttackEnemy()")
    tutorial_start = source.find("public int TutorialStep()", battle_start)
    if battle_start < 0 or tutorial_start < 0:
        errors.append("ApptyaGameState.cs: battle/tutorial methods are missing")
    else:
        battle = source[battle_start:tutorial_start]
        victory_branch = battle.find("if(army>=enemy)")
        tutorial_mark = battle.find("Data.tutorialBattled=true")
        defeat_branch = battle.find("else{int lost=", victory_branch)
        if victory_branch < 0 or tutorial_mark < 0 or defeat_branch < 0:
            errors.append("ApptyaGameState.cs: battle victory/defeat flow could not be verified")
        elif not (victory_branch < tutorial_mark < defeat_branch):
            errors.append("ApptyaGameState.cs: only a victory should complete the battle tutorial step")

    gather_start = source.find("public bool Gather(")
    upgrade_start = source.find("public bool UpgradeKeep()", gather_start)
    if gather_start < 0 or upgrade_start < 0:
        errors.append("ApptyaGameState.cs: resource gathering API is missing")
    else:
        gather = source[gather_start:upgrade_start]
        if "amount<=0" not in gather or "AddResourceSafely" not in gather:
            errors.append("ApptyaGameState.cs: gathering must reject non-positive amounts and use overflow-safe resource additions")
    # Guard troop training against free recruits and capacity overflows.
    train_start = source.find("public bool TrainGuard()")
    army_start = source.find("public int ArmyPower()", train_start)
    if train_start < 0 or army_start < 0:
        errors.append("ApptyaGameState.cs: guard training API is missing")
    else:
        train = source[train_start:army_start]
        for required_rule in ("Data.guards>=Data.barracksLevel*5", "Data.food<25", "Data.gold<10",
                              "Data.food-=25", "Data.gold-=10", "Data.guards++"):
            if required_rule not in train:
                errors.append(f"ApptyaGameState.cs: guard training is missing rule: {required_rule}")

    # Scout must consume a guard and refuse when no guard is available.
    scout_start = source.find("public bool Scout()")
    if scout_start < 0:
        errors.append("ApptyaGameState.cs: scouting API is missing")
    else:
        scout = source[scout_start:]
        if "Data.guards<1" not in scout or "Data.guards--" not in scout or "Save()" not in scout:
            errors.append("ApptyaGameState.cs: scouting must require and consume a guard, then save")

    # Claimed achievements must not be claimable repeatedly.
    achievement_start = source.find("public string ClaimAchievement(")
    scout_start = source.find("public bool Scout()", achievement_start)
    if achievement_start < 0 or scout_start < 0:
        errors.append("ApptyaGameState.cs: achievement/scouting methods are missing")
    else:
        achievements = source[achievement_start:scout_start]
        for claim_flag in ("rewardFirstVictoryClaimed", "rewardExplorerClaimed", "rewardKeepClaimed"):
            if claim_flag not in achievements or "already claimed" not in achievements:
                errors.append(f"ApptyaGameState.cs: achievement reward protection missing for {claim_flag}")

    # Save/load invariants: keep damaged timer values finite and offline rewards bounded.
    for required_rule in (
        "SanitizeTimer(Data.keepUpgradeRemaining)",
        "float.IsNaN(value)||float.IsInfinity(value)",
        "Mathf.Min(elapsed,28800f)",
        "PlayerPrefs.SetString(BackupKey,snapshot)",
        "loaded=TryReadSave(PlayerPrefs.GetString(BackupKey))",
        "AddResourceSafely(Data.wood,gainedWood)",
    ):
        if required_rule not in source:
            errors.append(f"ApptyaGameState.cs: save/offline-progression safeguard missing: {required_rule}")

    # Long campaign levels must not turn the enemy building into an enormous mesh.
    visuals_path = ROOT / "UnityProject/Assets/Scripts/ApptyaBuildingVisuals.cs"
    if visuals_path.is_file():
        visuals = visuals_path.read_text(encoding="utf-8")
        if "Mathf.Clamp(state.Data.enemyLevel, 1, 12)" not in visuals:
            errors.append("ApptyaBuildingVisuals.cs: enemy visual threat tier must be capped independently of gameplay level")
        if "visualThreatTier - 1" not in visuals:
            errors.append("ApptyaBuildingVisuals.cs: enemy roof scaling must use the capped visual tier")
        if "guardMarkers = new GameObject[25]" not in visuals:
            errors.append("ApptyaBuildingVisuals.cs: visible guard markers must cover the 25-guard barracks capacity")
    else:
        errors.append("ApptyaBuildingVisuals.cs: building visuals source is missing")

    # Building selection should tint every separately tappable mesh piece for the same building.
    tap_path = ROOT / "UnityProject/Assets/Scripts/ApptyaBuildingTap.cs"
    if tap_path.is_file():
        tap = tap_path.read_text(encoding="utf-8")
        if "FindObjectsOfType<ApptyaBuildingTap>()" not in tap or "part.buildingKey == buildingKey" not in tap:
            errors.append("ApptyaBuildingTap.cs: selection must highlight all mesh parts sharing a building key")
        if "!IsPointerOverUI()" not in tap and "if (IsPointerOverUI()) return;" not in tap:
            errors.append("ApptyaBuildingTap.cs: world selection must ignore taps over UI")
    else:
        errors.append("ApptyaBuildingTap.cs: building tap source is missing")

    # HUD regression checks: keep touch actions scrollable and safe-area aware.
    hud_path = ROOT / "UnityProject/Assets/Scripts/ApptyaRuntimeHud.cs"
    if hud_path.is_file():
        hud = hud_path.read_text(encoding="utf-8")
        for required in ("ApplySafeArea()", "Screen.safeArea", "ScrollRect", "AttackSelectedTarget",
                         "CollectFromSelectedBuilding", "UpgradeSelectedBuilding", "selectionInfo",
                         "UpdateSelectionInfo()", "Selected Building Details",
                         "ApptyaGameState.Instance == null || ApptyaGameState.Instance.Data == null"):
            if required not in hud:
                errors.append(f"ApptyaRuntimeHud.cs: required HUD safety/interaction feature missing: {required}")
        if "ApptyaGameState.Instance.Changed -= Refresh;" not in hud:
            errors.append("ApptyaRuntimeHud.cs: Changed event must be unsubscribed on destroy")
        if "ApptyaGameState.Instance.OfflineProgressApplied -= Say;" not in hud:
            errors.append("ApptyaRuntimeHud.cs: offline progress event must be unsubscribed on destroy")
        for feedback in ("Could not gather wood.", "Could not harvest food.", "state == null || state.Data == null"):
            if feedback not in hud:
                errors.append(f"ApptyaRuntimeHud.cs: missing action failure guard/feedback: {feedback}")
    else:
        errors.append("ApptyaRuntimeHud.cs: HUD source is missing")

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
    errors.extend(gameplay_invariants())
    if errors:
        print("Apptya Kingdom source preflight FAILED:")
        print("\n".join(f"- {error}" for error in errors))
        return 1
    print(f"Apptya Kingdom source preflight passed: {len(REQUIRED)} required files, valid package manifest, expected Unity version, and balanced C# delimiters.")
    print("Note: this is a static check only; it does not compile Unity scripts, run gameplay, or build an APK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
