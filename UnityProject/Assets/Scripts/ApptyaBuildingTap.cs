using UnityEngine;
using UnityEngine.EventSystems;

namespace ApptyaKingdom
{
    /// <summary>Tap-to-inspect interaction with a simple visible selection tint.</summary>
    public class ApptyaBuildingTap : MonoBehaviour
    {
        [SerializeField] string buildingKey;
        [SerializeField] string displayName;
        static ApptyaBuildingTap selected;
        Renderer targetRenderer;
        MaterialPropertyBlock colorBlock;

        public void Configure(string key, string label)
        {
            buildingKey = key;
            displayName = label;
            CacheRenderer();
        }

        void Awake() { CacheRenderer(); EnsureCollider(); }

        void EnsureCollider()
        {
            if (GetComponent<Collider>() == null) gameObject.AddComponent<BoxCollider>();
        }

        void CacheRenderer()
        {
            if (targetRenderer != null) return;
            targetRenderer = GetComponent<Renderer>();
            // Keep only the renderer reference. Its shared material may change when a
            // building upgrades, so selection tint must always derive from the current base.
        }

        void OnMouseDown()
        {
            // Prevent world selection when a tap lands on a HUD button or scroll view.
            // On touch devices, check the active finger IDs; the mouse-style check covers editor input.
            if (IsPointerOverUI()) return;
            if (ApptyaRuntimeHud.Instance == null) return;

            var state = ApptyaGameState.Instance;
            if (state == null || state.Data == null) return;
            // A building is composed of several separately tappable mesh parts.
            // Highlight every part with the same key so selection reads as one building.
            var buildingParts = FindObjectsOfType<ApptyaBuildingTap>();
            foreach (var part in buildingParts)
                part.SetSelected(part.buildingKey == buildingKey);
            selected = this;
            ApptyaRuntimeHud.Instance.SelectBuilding(buildingKey, displayName);
        }

        bool IsPointerOverUI()
        {
            var eventSystem = EventSystem.current;
            if (eventSystem == null) return false;
            if (Input.touchCount > 0)
            {
                for (int i = 0; i < Input.touchCount; i++)
                {
                    if (eventSystem.IsPointerOverGameObject(Input.GetTouch(i).fingerId))
                        return true;
                }
                return false;
            }
            return eventSystem.IsPointerOverGameObject();
        }

        void SetSelected(bool value)
        {
            CacheRenderer();
            if (targetRenderer == null) return;
            if (!value)
            {
                // Clear the selection override instead of restoring a cached color; the
                // shared material may have changed since selection (for example on upgrade).
                targetRenderer.SetPropertyBlock(null);
                return;
            }
            if (colorBlock == null) colorBlock = new MaterialPropertyBlock();
            targetRenderer.GetPropertyBlock(colorBlock);
            Color baseColor = targetRenderer.sharedMaterial != null ? targetRenderer.sharedMaterial.color : Color.white;
            Color tint = Color.Lerp(baseColor, new Color(1f, .78f, .25f), .58f);
            colorBlock.SetColor("_Color", tint);
            colorBlock.SetColor("_BaseColor", tint);
            targetRenderer.SetPropertyBlock(colorBlock);
        }

        void OnDestroy()
        {
            if (selected == this) selected = null;
            if (targetRenderer != null) targetRenderer.SetPropertyBlock(null);
        }
    }
}