using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace ApptyaKingdom
{
    /// <summary>Responsive, scrollable first-pass HUD for narrow Android screens.</summary>
    public class ApptyaRuntimeHud : MonoBehaviour
    {
        public static ApptyaRuntimeHud Instance { get; private set; }
        Text stats, notice, selectionInfo;
        Font font;
        GameObject actionPanel;
        GameObject hudCanvasObject;
        RectTransform safeArea;
        Rect lastSafeArea;
        int lastScreenWidth;
        int lastScreenHeight;
        string selectedBuildingKey;
        string selectedBuildingName;

        void Start()
        {
            // A duplicate HUD would create overlapping canvases and duplicate button actions.
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            // The HUD depends on initialized game data; fail clearly instead of throwing
            // null-reference errors from every button if the starter scene is misconfigured.
            if (ApptyaGameState.Instance == null || ApptyaGameState.Instance.Data == null)
            {
                Debug.LogError("Apptya Kingdom: game state is missing. Run Apptya Kingdom > Setup Starter Scene.");
                enabled = false;
                return;
            }

            Instance = this;
            font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            hudCanvasObject = new GameObject("Apptya Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = hudCanvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = hudCanvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = .5f;

            var safeAreaObject = new GameObject("Safe Area", typeof(RectTransform));
            safeAreaObject.transform.SetParent(canvas.transform, false);
            safeArea = safeAreaObject.GetComponent<RectTransform>();
            ApplySafeArea();

            if (!FindObjectOfType<EventSystem>())
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var top = Panel(safeArea.transform, "Resource HUD", new Vector2(0, 1), new Vector2(1, 1),
                new Vector2(0, -12), new Vector2(0, 300));
            stats = TextAt(top.transform, "Resources", new Vector2(.5f, .5f), Vector2.zero,
                new Vector2(1000, 270), 25, TextAnchor.MiddleCenter);

            actionPanel = Panel(safeArea.transform, "Action HUD", new Vector2(.04f, 0), new Vector2(.96f, 0),
                new Vector2(0, 18), new Vector2(0, 620));
            notice = TextAt(actionPanel.transform, "Chronicle", new Vector2(.5f, 1f),
                new Vector2(0, -42), new Vector2(900, 62), 20, TextAnchor.MiddleCenter);
            selectionInfo = TextAt(actionPanel.transform, "Selected Building Details", new Vector2(.5f, 1f),
                new Vector2(0, -104), new Vector2(900, 54), 17, TextAnchor.MiddleCenter);
            selectionInfo.text = "Tap the Keep, a village building or the enemy outpost to inspect it.";

            var scrollObject = new GameObject("Action Scroll View", typeof(RectTransform), typeof(Image), typeof(ScrollRect));
            scrollObject.transform.SetParent(actionPanel.transform, false);
            var scrollRectTransform = scrollObject.GetComponent<RectTransform>();
            scrollRectTransform.anchorMin = new Vector2(0, 0);
            scrollRectTransform.anchorMax = new Vector2(1, 1);
            scrollRectTransform.offsetMin = new Vector2(12, 12);
            scrollRectTransform.offsetMax = new Vector2(-12, -150);
            scrollObject.GetComponent<Image>().color = new Color(.025f, .05f, .09f, .35f);

            var viewport = new GameObject("Viewport", typeof(RectTransform), typeof(Image), typeof(Mask));
            viewport.transform.SetParent(scrollObject.transform, false);
            var viewportRect = viewport.GetComponent<RectTransform>();
            viewportRect.anchorMin = Vector2.zero;
            viewportRect.anchorMax = Vector2.one;
            viewportRect.offsetMin = viewportRect.offsetMax = Vector2.zero;
            viewport.GetComponent<Image>().color = new Color(1, 1, 1, .015f);
            viewport.GetComponent<Mask>().showMaskGraphic = false;

            var contentObject = new GameObject("Action Grid", typeof(RectTransform), typeof(GridLayoutGroup), typeof(ContentSizeFitter));
            contentObject.transform.SetParent(viewport.transform, false);
            var contentRect = contentObject.GetComponent<RectTransform>();
            contentRect.anchorMin = new Vector2(0, 1);
            contentRect.anchorMax = new Vector2(1, 1);
            contentRect.pivot = new Vector2(.5f, 1);
            contentRect.anchoredPosition = Vector2.zero;
            contentRect.sizeDelta = Vector2.zero;
            var grid = contentObject.GetComponent<GridLayoutGroup>();
            grid.padding = new RectOffset(8, 8, 8, 8);
            grid.spacing = new Vector2(10, 10);
            grid.cellSize = new Vector2(285, 82);
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = 3;
            grid.childAlignment = TextAnchor.UpperCenter;
            var fitter = contentObject.GetComponent<ContentSizeFitter>();
            fitter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            fitter.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            var scroll = scrollObject.GetComponent<ScrollRect>();
            scroll.viewport = viewportRect;
            scroll.content = contentRect;
            scroll.horizontal = false;
            scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.verticalScrollbarVisibility = ScrollRect.ScrollbarVisibility.AutoHide;

            GridButton(contentObject.transform, "Gather wood +25", () => { var state = ApptyaGameState.Instance; Say(state != null && state.Gather("wood", 25) ? "Lumber Camp delivered +25 wood." : "Could not gather wood. Game state is unavailable."); });
            GridButton(contentObject.transform, "Harvest food +30", () => { var state = ApptyaGameState.Instance; Say(state != null && state.Gather("food", 30) ? "Farm delivered +30 food." : "Could not harvest food. Game state is unavailable."); });
            GridButton(contentObject.transform, "Queue infantry", () => QueueTroop("infantry"));
            GridButton(contentObject.transform, "Queue archers", () => QueueTroop("archer"));
            GridButton(contentObject.transform, "Queue cavalry", () => QueueTroop("cavalry"));
            GridButton(contentObject.transform, "Upgrade keep", UpgradeKeep);
            GridButton(contentObject.transform, "Scout wilds", () => { var state = ApptyaGameState.Instance; Say(state == null || state.Data == null ? "Game state is unavailable. Reopen the starter scene." : state.Scout() ? "Scouts returned with loot." : "Train a guard first."); });
            GridButton(contentObject.transform, "Attack enemy", () => { var state = ApptyaGameState.Instance; if (state == null || state.Data == null) { Say("Game state is unavailable. Reopen the starter scene."); return; } ShowBattleResult(state.AttackEnemy()); });
            GridButton(contentObject.transform, "Explore region", () => { var state = ApptyaGameState.Instance; Say(state == null || state.Data == null ? "Game state is unavailable. Reopen the starter scene." : state.ExploreRegion()); });
            GridButton(contentObject.transform, "Upgrade lumber", () => Upgrade("lumber", "Lumber Camp"));
            GridButton(contentObject.transform, "Upgrade farm", () => Upgrade("farm", "Farmstead"));
            GridButton(contentObject.transform, "Upgrade barracks", () => Upgrade("barracks", "Barracks"));
            GridButton(contentObject.transform, "Upgrade quarry", () => Upgrade("quarry", "Quarry"));
            GridButton(contentObject.transform, "Reward: First Victory", () => ClaimAchievement("first_victory"));
            GridButton(contentObject.transform, "Reward: Explorer", () => ClaimAchievement("explorer"));
            GridButton(contentObject.transform, "Reward: Keep Builder", () => ClaimAchievement("keep_builder"));
            GridButton(contentObject.transform, "Open Research Center", OpenResearchCenter);
            GridButton(contentObject.transform, "Research: Combat", () => Say(ApptyaGameState.Instance == null ? "Game state is unavailable." : ApptyaGameState.Instance.Research("combat")));
            GridButton(contentObject.transform, "Research: Economy", () => Say(ApptyaGameState.Instance == null ? "Game state is unavailable." : ApptyaGameState.Instance.Research("economy")));
            GridButton(contentObject.transform, "Research: Cartography", () => Say(ApptyaGameState.Instance == null ? "Game state is unavailable." : ApptyaGameState.Instance.Research("scouting")));
            GridButton(contentObject.transform, "Upgrade selected", UpgradeSelectedBuilding);
            GridButton(contentObject.transform, "Collect selected", CollectFromSelectedBuilding);
            GridButton(contentObject.transform, "Attack selected", AttackSelectedTarget);
            GridButton(contentObject.transform, "Practice troops", PracticeSelectedTarget);

            ApptyaGameState.Instance.Changed += Refresh;
            ApptyaGameState.Instance.OfflineProgressApplied += Say;
            Refresh();
            if (!string.IsNullOrEmpty(ApptyaGameState.Instance.LastOfflineSummary))
                Say(ApptyaGameState.Instance.LastOfflineSummary);
        }

        void Update()
        {
            if (safeArea == null) return;
            if (lastScreenWidth != Screen.width || lastScreenHeight != Screen.height || lastSafeArea != Screen.safeArea)
                ApplySafeArea();
        }

        void ApplySafeArea()
        {
            if (safeArea == null) return;
            Rect area = Screen.safeArea;
            // Avoid invalid anchors before display dimensions are initialized.
            if (Screen.width <= 0 || Screen.height <= 0)
            {
                safeArea.anchorMin = Vector2.zero;
                safeArea.anchorMax = Vector2.one;
                return;
            }
            safeArea.anchorMin = new Vector2(area.xMin / Screen.width, area.yMin / Screen.height);
            safeArea.anchorMax = new Vector2(area.xMax / Screen.width, area.yMax / Screen.height);
            safeArea.offsetMin = Vector2.zero;
            safeArea.offsetMax = Vector2.zero;
            lastSafeArea = area;
            lastScreenWidth = Screen.width;
            lastScreenHeight = Screen.height;
        }

        void OnDestroy()
        {
            if (ApptyaGameState.Instance != null)
            {
                ApptyaGameState.Instance.Changed -= Refresh;
                ApptyaGameState.Instance.OfflineProgressApplied -= Say;
            }
            if (Instance == this) Instance = null;
            // The canvas is created at runtime as a sibling of this component, so clean it
            // up explicitly if the HUD is removed without unloading the whole scene.
            if (hudCanvasObject != null) Destroy(hudCanvasObject);
        }

        public void SelectBuilding(string key, string displayName)
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) return;
            selectedBuildingKey = key;
            selectedBuildingName = displayName;
            UpdateSelectionInfo();
            Say(displayName + " selected.");
        }

        void UpdateSelectionInfo()
        {
            if (selectionInfo == null) return;
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                selectionInfo.text = "Game state is unavailable. Reopen the starter scene.";
                return;
            }
            if (string.IsNullOrEmpty(selectedBuildingKey))
            {
                selectionInfo.text = "Tap the Keep, a village building or the enemy outpost to inspect it.";
                return;
            }

            var d = state.Data;
            if (selectedBuildingKey == "practice")
            {
                selectionInfo.text = selectedBuildingName + " • Drills " + d.practiceDrills + "/20 • Army power bonus +" + d.practiceDrills + " • Select Practice troops.";
                return;
            }
            if (selectedBuildingKey == "enemy")
            {
                selectionInfo.text = selectedBuildingName + " • Level " + d.enemyLevel + " • Power " + state.EnemyPower() +
                    " • Train guards and upgrade buildings before using Attack selected.";
                return;
            }
            if (selectedBuildingKey == "keep")
            {
                int level = d.keepLevel;
                if (state.IsUpgradeActive("keep"))
                    selectionInfo.text = selectedBuildingName + " • Level " + level + "/10 • Upgrade in progress: " +
                        Mathf.CeilToInt(state.UpgradeTimeRemaining("keep")) + "s remaining.";
                else if (level >= 10)
                    selectionInfo.text = selectedBuildingName + " • MAX LEVEL 10 • Keep fully upgraded.";
                else
                    selectionInfo.text = selectedBuildingName + " • Level " + level + "/10 • Next: " +
                        (80 * level) + " wood + " + (45 * level) + " stone • Use Upgrade selected.";
                return;
            }

            int buildingLevel = state.GetBuildingLevel(selectedBuildingKey);
            if (buildingLevel < 1)
            {
                selectionInfo.text = selectedBuildingName + " • No building data available.";
                return;
            }
            if (selectedBuildingKey == "barracks")
            {
                selectionInfo.text = selectedBuildingName + " • Level " + buildingLevel + "/5 • Guards " +
                    d.guards + "/" + (d.barracksLevel * 5) + " • Combat bonus +"+(d.combatResearch*2)+" power/guard • Train 1 guard: 25 food + 10 gold" +
                    (state.IsUpgradeActive("barracks")
                        ? " • Upgrade: " + Mathf.CeilToInt(state.UpgradeTimeRemaining("barracks")) + "s remaining."
                        : buildingLevel >= 5 ? " • MAX LEVEL." : " • Next upgrade: " +
                            (35 * buildingLevel) + " wood + " + (20 * buildingLevel) + " stone + " +
                            (10 * buildingLevel) + " gold.");
                return;
            }
            if (selectedBuildingKey == "lumber" || selectedBuildingKey == "farm" || selectedBuildingKey == "quarry")
            {
                string output = selectedBuildingKey == "lumber" ? "wood +" + (5 * buildingLevel) + "/30s"
                    : selectedBuildingKey == "farm" ? "food +" + (6 * buildingLevel) + "/30s"
                    : "stone +" + (3 * buildingLevel) + "/30s";
                selectionInfo.text = selectedBuildingName + " • Level " + buildingLevel + "/5 • " + output +
                    (state.IsUpgradeActive(selectedBuildingKey)
                        ? " • Upgrade: " + Mathf.CeilToInt(state.UpgradeTimeRemaining(selectedBuildingKey)) + "s remaining."
                        : buildingLevel >= 5 ? " • MAX LEVEL." : " • Next upgrade: " +
                            (35 * buildingLevel) + " wood + " + (20 * buildingLevel) + " stone + " +
                            (10 * buildingLevel) + " gold.");
                return;
            }
            if (state.IsUpgradeActive(selectedBuildingKey))
                selectionInfo.text = selectedBuildingName + " • Level " + buildingLevel + "/5 • Upgrade in progress: " +
                    Mathf.CeilToInt(state.UpgradeTimeRemaining(selectedBuildingKey)) + "s remaining.";
            else if (buildingLevel >= 5)
                selectionInfo.text = selectedBuildingName + " • MAX LEVEL 5 • Building fully upgraded.";
            else
                selectionInfo.text = selectedBuildingName + " • Level " + buildingLevel + "/5 • Next: " +
                    (35 * buildingLevel) + " wood + " + (20 * buildingLevel) + " stone + " +
                    (10 * buildingLevel) + " gold • Use Upgrade selected.";
        }

        void Refresh()
        {
            var state = ApptyaGameState.Instance;
            if (stats == null || state == null || state.Data == null) return;
            var d = state.Data;
            stats.text = "APPTYA KINGDOM  |  KEEP " + d.keepLevel + (state.IsUpgradeActive("keep") ? " (UP " + Mathf.CeilToInt(state.UpgradeTimeRemaining("keep")) + "s)" : "") + "  |  DAY " + d.day + "  |  ENEMY LV " + d.enemyLevel +
                "\nWOOD " + d.wood + "  FOOD " + d.food + "  STONE " + d.stone + "  GOLD " + d.gold +
                "\nTROOPS INF " + d.infantry + "  ARCH " + d.archers + "  CAV " + d.cavalry + "  | TOTAL " + d.guards + "/" + (d.barracksLevel * 5) + "  | POWER " + state.ArmyPower() + "\nTRAINING: " + state.TroopTrainingStatus() +
                "\nRESEARCH: COMBAT " + d.combatResearch + "/5 (" + ResearchRequirement(d.combatResearch, true) + ")  ECONOMY " + d.economyResearch + "/5 (" + ResearchRequirement(d.economyResearch, false) + ")  CARTOGRAPHY " + d.scoutingResearch + "/5 (" + ResearchRequirement(d.scoutingResearch, false) + ")" +
                "\nPRODUCTION / 30s: WOOD +" + (5 * d.lumberLevel + d.economyResearch) + "  FOOD +" + (6 * d.farmLevel + d.economyResearch) +
                "  STONE +" + (3 * d.quarryLevel + d.economyResearch) + "  GOLD +" + (2 * d.keepLevel) +
                "\nBUILDINGS: " + UpgradeStatus("lumber", "LUMBER " + d.lumberLevel) + "  " + UpgradeStatus("farm", "FARM " + d.farmLevel) + "  " + UpgradeStatus("barracks", "BARRACKS " + d.barracksLevel) +
                "  " + UpgradeStatus("quarry", "QUARRY " + d.quarryLevel) + "\nBATTLES: WINS " + d.victories + "  LOSSES " + d.defeats + "  REGIONS " + d.exploredRegions + "\n" + state.TutorialObjective();
            UpdateSelectionInfo();
        }

        string ResearchRequirement(int currentLevel, bool combat)
        {
            if (currentLevel >= 5) return "MAX";
            int requiredLevel = currentLevel + 1;
            return combat
                ? "next needs Keep " + requiredLevel + " + Barracks " + requiredLevel
                : "next needs Keep " + requiredLevel;
        }

        string UpgradeStatus(string key, string label)
        {
            var state = ApptyaGameState.Instance;
            if (state.GetBuildingLevel(key) >= 5) return label + " • MAX";
            return state.IsUpgradeActive(key) ? label + " • " + Mathf.CeilToInt(state.UpgradeTimeRemaining(key)) + "s" : label + " • IDLE";
        }

        void OpenResearchCenter()
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) { Say("Game state is unavailable. Reopen the starter scene."); return; }
            var existing = GameObject.Find("Research Center Overlay");
            if (existing) Destroy(existing);
            Transform parent = safeArea != null ? safeArea.transform : hudCanvasObject.transform;
            var panel = Panel(parent, "Research Center Overlay", new Vector2(.04f, .16f), new Vector2(.96f, .84f), Vector2.zero, Vector2.zero);
            var title = TextAt(panel.transform, "Research Center Title", new Vector2(.5f, 1f), new Vector2(0, -38), new Vector2(800, 58), 30, TextAnchor.MiddleCenter);
            title.text = "RESEARCH CENTER";
            var details = TextAt(panel.transform, "Research Center Details", new Vector2(.5f, .58f), new Vector2(0, -10), new Vector2(820, 330), 21, TextAnchor.MiddleCenter);
            details.horizontalOverflow = HorizontalWrapMode.Wrap;
            details.text = ResearchCenterSummary(state);
            ButtonAt(panel.transform, "Research Combat Drills", new Vector2(0, -190), () => ResearchFromCenter("combat", details), 620);
            ButtonAt(panel.transform, "Research Efficient Production", new Vector2(0, -250), () => ResearchFromCenter("economy", details), 620);
            ButtonAt(panel.transform, "Research Cartography", new Vector2(0, -310), () => ResearchFromCenter("scouting", details), 620);
            ButtonAt(panel.transform, "Close Research", new Vector2(0, -370), () => Destroy(panel), 260);
        }

        string ResearchCenterSummary(ApptyaGameState state)
        {
            var d = state.Data;
            return "COMBAT DRILLS  " + d.combatResearch + "/5\n+2 power per troop per level\n" + ResearchCostAndGate(d.combatResearch, true) +
                "\n\nEFFICIENT PRODUCTION  " + d.economyResearch + "/5\n+1 wood, food and stone per level every 30 seconds\n" + ResearchCostAndGate(d.economyResearch, false) +
                "\n\nCARTOGRAPHY  " + d.scoutingResearch + "/5\nImproves exploration loot\n" + ResearchCostAndGate(d.scoutingResearch, false) +
                "\n\nCosts per next level: 60 wood + 40 stone + 25 gold, multiplied by the next level.";
        }

        string ResearchCostAndGate(int level, bool combat)
        {
            if (level >= 5) return "MAX LEVEL";
            int next = level + 1;
            var state = ApptyaGameState.Instance;
            return "Next: " + (60 * next) + " wood / " + (40 * next) + " stone / " + (25 * next) +
                " gold • Requires Keep " + next + (combat ? " and Barracks " + next : "") +
                (state.Data.keepLevel < next || (combat && state.Data.barracksLevel < next) ? " • LOCKED" : " • AVAILABLE");
        }

        void ResearchFromCenter(string branch, Text details)
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) { Say("Game state is unavailable."); return; }
            string result = state.Research(branch);
            Say(result);
            Refresh();
            details.text = ResearchCenterSummary(state);
        }

        void QueueTroop(string type)
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) { Say("Game state is unavailable. Reopen the starter scene."); return; }
            if (state.QueueTroop(type)) Say(type + " training started. " + state.TroopTrainingStatus());
            else Say("Cannot queue " + type + ": check food/gold, Barracks capacity and whether the queue is idle.");
        }

        void ShowBattleResult(string result)
        {
            Say(result);
            var old = GameObject.Find("Battle Result Overlay");
            if (old) Destroy(old);
            var canvas = FindObjectOfType<Canvas>();
            if (!canvas) return;
            Transform overlayParent = safeArea != null ? safeArea.transform : canvas.transform;
            var overlay = Panel(overlayParent, "Battle Result Overlay", new Vector2(.06f, .28f),
                new Vector2(.94f, .72f), Vector2.zero, Vector2.zero);
            var title = TextAt(overlay.transform, "Battle Title", new Vector2(.5f, 1f),
                new Vector2(0, -48), new Vector2(700, 70), 32, TextAnchor.MiddleCenter);
            title.text = result.StartsWith("VICTORY") ? "VICTORY" : "BATTLE REPORT";
            title.color = result.StartsWith("VICTORY") ? new Color(1f, .78f, .25f) : Color.white;
            var body = TextAt(overlay.transform, "Battle Details", new Vector2(.5f, .5f),
                Vector2.zero, new Vector2(760, 220), 23, TextAnchor.MiddleCenter);
            body.text = result;
            body.horizontalOverflow = HorizontalWrapMode.Wrap;
            ButtonAt(overlay.transform, "Continue", new Vector2(0, -145), () => Destroy(overlay), 220);
        }

        void UpgradeSelectedBuilding()
        {
            if (string.IsNullOrEmpty(selectedBuildingKey))
            {
                Say("Tap the Keep or a village building first.");
                return;
            }
            if (selectedBuildingKey == "keep") { UpgradeKeep(); return; }
            if (selectedBuildingKey == "enemy") { Say("The enemy outpost cannot be upgraded. Use Attack selected."); return; }
            Upgrade(selectedBuildingKey, selectedBuildingName);
        }

        void PracticeSelectedTarget()
        {
            if (selectedBuildingKey != "practice")
            {
                Say("Tap the visible Practice Target in the valley first.");
                return;
            }
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                Say("Game state is unavailable. Reopen the starter scene.");
                return;
            }
            var d = state.Data;
            if (d.guards < 1)
            {
                Say("No troops are available to practice. Queue infantry, archers or cavalry first.");
                return;
            }
            Say(state.PracticeTroops() + " Army power: " + state.ArmyPower() + " • Infantry " + d.infantry +
                " • Archers " + d.archers + " • Cavalry " + d.cavalry + ".");
        }

        void AttackSelectedTarget()
        {
            if (selectedBuildingKey != "enemy")
            {
                Say("Tap the enemy outpost first to select it as your target.");
                return;
            }
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                Say("Game state is unavailable. Reopen the starter scene.");
                return;
            }
            ShowBattleResult(state.AttackEnemy());
        }

        void CollectFromSelectedBuilding()
        {
            if (string.IsNullOrEmpty(selectedBuildingKey))
            {
                Say("Tap the Lumber Camp, Farmstead or Quarry first.");
                return;
            }
            string resource;
            int amount;
            switch (selectedBuildingKey)
            {
                case "lumber": resource = "wood"; amount = 25; break;
                case "farm": resource = "food"; amount = 30; break;
                case "quarry": resource = "stone"; amount = 20; break;
                default:
                    Say(selectedBuildingName + " does not produce a directly collectable resource.");
                    return;
            }
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                Say("Game state is unavailable. Reopen the starter scene.");
                return;
            }
            if (state.Gather(resource, amount))
                Say(selectedBuildingName + " delivered +" + amount + " " + resource + ".");
            else
                Say("Could not collect resources. Try again.");
        }

        void Say(string message) { if (notice) notice.text = message; }

        void ClaimAchievement(string id)
        {
            var state = ApptyaGameState.Instance;
            Say(state == null || state.Data == null
                ? "Game state is unavailable. Reopen the starter scene."
                : state.ClaimAchievement(id));
        }

        void UpgradeKeep()
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                Say("Game state is unavailable. Reopen the starter scene.");
                return;
            }
            int level = state.Data.keepLevel;
            if (level >= 10) { Say("Keep is already at maximum level 10."); return; }
            int wood = 80 * level, stone = 45 * level;
            if (state.IsUpgradeActive("keep")) { Say("Keep upgrade already in progress: " + Mathf.CeilToInt(state.UpgradeTimeRemaining("keep")) + "s remaining."); return; }
            Say(state.UpgradeKeep() ? "Keep upgrade started. Level " + (level + 1) + " in " + Mathf.CeilToInt(state.UpgradeTimeRemaining("keep")) + " seconds." :
                "Need " + wood + " wood and " + stone + " stone to upgrade the keep.");
        }

        void Upgrade(string key, string label)
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null)
            {
                Say("Game state is unavailable. Reopen the starter scene.");
                return;
            }
            int level = state.GetBuildingLevel(key);
            if (level >= 5) { Say(label + " is already at maximum level 5."); return; }
            if (state.IsUpgradeActive(key)) { Say(label + " upgrade already in progress: " + Mathf.CeilToInt(state.UpgradeTimeRemaining(key)) + "s remaining."); return; }
            Say(state.UpgradeBuilding(key) ? label + " upgrade started. Level " + (level + 1) + " in " + Mathf.CeilToInt(state.UpgradeTimeRemaining(key)) + " seconds." :
                "Need " + (35 * level) + " wood, " + (20 * level) + " stone and " + (10 * level) + " gold.");
        }

        GameObject Panel(Transform parent, string name, Vector2 anchorMin, Vector2 anchorMax, Vector2 position, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin; rect.anchorMax = anchorMax;
            // Edge-anchored HUD panels must pivot on that edge; the default center pivot
            // would push half the panel outside the safe area on portrait screens.
            if (Mathf.Approximately(anchorMin.y, 1f) && Mathf.Approximately(anchorMax.y, 1f))
                rect.pivot = new Vector2(.5f, 1f);
            else if (Mathf.Approximately(anchorMin.y, 0f) && Mathf.Approximately(anchorMax.y, 0f))
                rect.pivot = new Vector2(.5f, 0f);
            else
                rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = position; rect.sizeDelta = size;
            go.GetComponent<Image>().color = new Color(.035f, .075f, .13f, .94f);
            return go;
        }

        Text TextAt(Transform parent, string name, Vector2 anchor, Vector2 position, Vector2 size, int fontSize, TextAnchor alignment)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = anchor;
            rect.anchoredPosition = position; rect.sizeDelta = size;
            var text = go.GetComponent<Text>();
            text.font = font; text.fontSize = fontSize; text.alignment = alignment;
            text.color = Color.white; text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        void GridButton(Transform parent, string label, UnityEngine.Events.UnityAction action)
        {
            var go = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button), typeof(LayoutElement));
            go.transform.SetParent(parent, false);
            go.GetComponent<LayoutElement>().preferredHeight = 82;
            go.GetComponent<Image>().color = new Color(.13f, .25f, .38f);
            go.GetComponent<Button>().onClick.AddListener(action);
            var textObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            textObject.transform.SetParent(go.transform, false);
            var rect = textObject.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(5, 3); rect.offsetMax = new Vector2(-5, -3);
            var text = textObject.GetComponent<Text>();
            text.font = font; text.fontSize = 20; text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter; text.color = Color.white; text.text = label;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
        }

        void ButtonAt(Transform parent, string label, Vector2 position, UnityEngine.Events.UnityAction action, float width)
        {
            var go = new GameObject(label, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.anchoredPosition = position; rect.sizeDelta = new Vector2(width, 76);
            go.GetComponent<Image>().color = new Color(.13f, .25f, .38f);
            go.GetComponent<Button>().onClick.AddListener(action);
            var textObject = new GameObject("Label", typeof(RectTransform), typeof(Text));
            textObject.transform.SetParent(go.transform, false);
            var textRect = textObject.GetComponent<RectTransform>();
            textRect.anchorMin = Vector2.zero; textRect.anchorMax = Vector2.one;
            textRect.offsetMin = textRect.offsetMax = Vector2.zero;
            var text = textObject.GetComponent<Text>();
            text.font = font; text.fontSize = 22; text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter; text.color = Color.white; text.text = label;
        }
    }
}