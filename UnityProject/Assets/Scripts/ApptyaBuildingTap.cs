using UnityEngine;

namespace ApptyaKingdom
{
    /// <summary>Tap-to-inspect interaction with a simple visible selection tint.</summary>
    public class ApptyaBuildingTap : MonoBehaviour
    {
        [SerializeField] string buildingKey;
        [SerializeField] string displayName;
        static ApptyaBuildingTap selected;
        Renderer targetRenderer;
        Color originalColor;
        bool hasOriginalColor;

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
            if (targetRenderer != null)
            {
                originalColor = targetRenderer.material.color;
                hasOriginalColor = true;
            }
        }

        void OnMouseDown()
        {
            if (ApptyaRuntimeHud.Instance == null) return;
            if (selected != null) selected.SetSelected(false);
            selected = this;
            SetSelected(true);
            ApptyaRuntimeHud.Instance.SelectBuilding(buildingKey, displayName);
        }

        void SetSelected(bool value)
        {
            CacheRenderer();
            if (targetRenderer == null || !hasOriginalColor) return;
            targetRenderer.material.color = value ? Color.Lerp(originalColor, new Color(1f, .78f, .25f), .58f) : originalColor;
        }

        void OnDestroy()
        {
            if (selected == this) selected = null;
        }
    }
}