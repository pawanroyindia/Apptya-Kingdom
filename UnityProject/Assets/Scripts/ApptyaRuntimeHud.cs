using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace ApptyaKingdom
{
    /// <summary>Responsive, scrollable first-pass HUD for narrow Android screens.</summary>
    public class ApptyaRuntimeHud : MonoBehaviour
    {
        public static ApptyaRuntimeHud Instance { get; private set; }
        Text stats, notice;
        Font font;
        GameObject actionPanel;
        string selectedBuildingKey;
        string selectedBuildingName;

        void Start()
        {
            Instance = this;
            font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            var canvasObject = new GameObject("Apptya Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920);
            scaler.matchWidthOrHeight = .5f;

            if (!FindObjectOfType<EventSystem>())
                new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            var top = Panel(canvas.transform, "Resource HUD", new Vector2(0, 1), new Vector2(1, 1),
                new Vector2(0, -12), new Vector2(0, 300));
            stats = TextAt(top.transform, "Resources", new Vector2(.5f, .5f), Vector2.zero,
                new Vector2(1000, 270), 25, TextAnchor.MiddleCenter);

            actionPanel = Panel(canvas.transform, "Action HUD", new Vector2(.04f, 0), new Vector2(.96f, 0),
                new Vector2(0, 18), new Vector2(0, 620));
            notice = TextAt(actionPanel.transform, "Chronicle", new Vector2(.5f, 1f),
                new Vector2(0, -42), new Vector2(900, 62), 20, TextAnchor.MiddleCenter);

            var scrollObject = new GameObject("Action Scroll View", typeof(RectTransform), typeof(Image), typeof(ScrollRect));
            scrollObject.transform.SetParent(actionPanel.transform, false);
            var scrollRectTransform = scrollObject.GetComponent<RectTransform>();
            scrollRectTransform.anchorMin = new Vector2(0, 0);
            scrollRectTransform.anchorMax = new Vector2(1, 1);
            scrollRectTransform.offsetMin = new Vector2(12, 12);
            scrollRectTransform.offsetMax = new Vector2(-12, -90);
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

            GridButton(contentObject.transform, "Gather wood +25", () => { ApptyaGameState.Instance.Gather("wood", 25); Say("Lumber Camp delivered wood."); });
            GridButton(contentObject.transform, "Harvest food +30", () => { ApptyaGameState.Instance.Gather("food", 30); Say("Farm delivered food."); });
            GridButton(contentObject.transform, "Train guard", () => Say(ApptyaGameState.Instance.TrainGuard() ? "A guard joined the army." : "Need 25 food, 10 gold and free barracks capacity."));
            GridButton(contentObject.transform, "Upgrade keep", UpgradeKeep);
            GridButton(contentObject.transform, "Scout wilds", () => Say(ApptyaGameState.Instance.Scout() ? "Scouts returned with loot." : "Train a guard first."));
            GridButton(contentObject.transform, "Attack enemy", () => ShowBattleResult(ApptyaGameState.Instance.AttackEnemy()));
            GridButton(contentObject.transform, "Explore region", () => Say(ApptyaGameState.Instance.ExploreRegion()));
            GridButton(contentObject.transform, "Upgrade lumber", () => Upgrade("lumber", "Lumber Camp"));
            GridButton(contentObject.transform, "Upgrade farm", () => Upgrade("farm", "Farmstead"));
            GridButton(contentObject.transform, "Upgrade barracks", () => Upgrade("barracks", "Barracks"));
            GridButton(contentObject.transform, "Upgrade quarry", () => Upgrade("quarry", "Quarry"));
            GridButton(contentObject.transform, "Reward: First Victory", () => Say(ApptyaGameState.Instance.ClaimAchievement("first_victory")));
            GridButton(contentObject.transform, "Reward: Explorer", () => Say(ApptyaGameState.Instance.ClaimAchievement("explorer")));
            GridButton(contentObject.transform, "Reward: Keep Builder", () => Say(ApptyaGameState.Instance.ClaimAchievement("keep_builder")));
            GridButton(contentObject.transform, "Upgrade selected", UpgradeSelectedBuilding);
            GridButton(contentObject.transform, "Collect selected", CollectFromSelectedBuilding);
            GridButton(contentObject.transform, "Attack selected", AttackSelectedTarget);

            ApptyaGameState.Instance.Changed += Refresh;
            Refresh();
        }

        void OnDestroy()
        {
            if (ApptyaGameState.Instance != null) ApptyaGameState.Instance.Changed -= Refresh;
            if (Instance == this) Instance = null;
        }

        public void SelectBuilding(string key, string displayName)
        {
            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) return;
            selectedBuildingKey = key;
            selectedBuildingName = displayName;
            if (key == "enemy")
            {
                Say(displayName + " • Enemy level " + state.Data.enemyLevel + " • Enemy power " + state.EnemyPower() + ". Train guards and upgrade before attacking.");
                return;
            }
            if (key == "keep")
            {
                int level = state.Data.keepLevel;
                Say(displayName + " • Level " + level + "/10 • Upgrade: " + (80 * level) + " wood + " + (45 * level) + " stone. Use Upgrade Keep below.");
                return;
            }
            int buildingLevel = state.GetBuildingLevel(key);
            if (buildingLevel < 1) return;
            Say(displayName + " • Level " + buildingLevel + "/5 • Upgrade: " + (35 * buildingLevel) + " wood + " + (20 * buildingLevel) + " stone + " + (10 * buildingLevel) + " gold. Use its upgrade action below.");
        }

        void Refresh()
        {
            if (stats == null || ApptyaGameState.Instance == null) return;
            var d = ApptyaGameState.Instance.Data;
            stats.text = "APPTYA KINGDOM  |  KEEP " + d.keepLevel + "  |  DAY " + d.day + "  |  ENEMY LV " + d.enemyLevel +
                "\nWOOD " + d.wood + "  FOOD " + d.food + "  STONE " + d.stone + "  GOLD " + d.gold +
                "\nGUARDS " + d.guards + "/" + (d.barracksLevel * 5) + "  |  ARMY POWER " + ApptyaGameState.Instance.ArmyPower() +
                "\nPRODUCTION / 30s: WOOD +" + (5 * d.lumberLevel) + "  FOOD +" + (6 * d.farmLevel) +
                "  STONE +" + (3 * d.quarryLevel) + "  GOLD +" + (2 * d.keepLevel) +
                "\nBUILDINGS: LUMBER " + d.lumberLevel + "  FARM " + d.farmLevel + "  BARRACKS " + d.barracksLevel +
                "  QUARRY " + d.quarryLevel + "\nBATTLES: WINS " + d.victories + "  LOSSES " + d.defeats + "  REGIONS " + d.exploredRegions + "\n" + ApptyaGameState.Instance.TutorialObjective();
        }

        void ShowBattleResult(string result)
        {
            Say(result);
            var old = GameObject.Find("Battle Result Overlay");
            if (old) Destroy(old);
            var canvas = FindObjectOfType<Canvas>();
            if (!canvas) return;
            var overlay = Panel(canvas.transform, "Battle Result Overlay", new Vector2(.06f, .28f),
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
            Upgrade(selectedBuildingKey, selectedBuildingName);
        }

        void AttackSelectedTarget()
        {
            if (selectedBuildingKey != "enemy")
            {
                Say("Tap the enemy outpost first to select it as your target.");
                return;
            }
            ShowBattleResult(ApptyaGameState.Instance.AttackEnemy());
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
            ApptyaGameState.Instance.Gather(resource, amount);
            Say(selectedBuildingName + " delivered +" + amount + " " + resource + ".");
        }

        void Say(string message) { if (notice) notice.text = message; }

        void UpgradeKeep()
        {
            var state = ApptyaGameState.Instance;
            int level = state.Data.keepLevel;
            if (level >= 10) { Say("Keep is already at maximum level 10."); return; }
            int wood = 80 * level, stone = 45 * level;
            Say(state.UpgradeKeep() ? "Keep upgraded to level " + (level + 1) + "!" :
                "Need " + wood + " wood and " + stone + " stone to upgrade the keep.");
        }

        void Upgrade(string key, string label)
        {
            var state = ApptyaGameState.Instance;
            int level = state.GetBuildingLevel(key);
            if (level >= 5) { Say(label + " is already at maximum level 5."); return; }
            Say(state.UpgradeBuilding(key) ? label + " upgraded to level " + (level + 1) + "!" :
                "Need " + (35 * level) + " wood, " + (20 * level) + " stone and " + (10 * level) + " gold.");
        }

        GameObject Panel(Transform parent, string name, Vector2 anchorMin, Vector2 anchorMax, Vector2 position, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = anchorMin; rect.anchorMax = anchorMax;
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