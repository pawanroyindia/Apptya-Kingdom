using UnityEngine;

namespace ApptyaKingdom
{
    /// <summary>Allows tapping a major building to inspect its level and upgrade requirements.</summary>
    public class ApptyaBuildingTap : MonoBehaviour
    {
        [SerializeField] string buildingKey;
        [SerializeField] string displayName;

        public void Configure(string key, string label)
        {
            buildingKey = key;
            displayName = label;
        }

        void OnMouseDown()
        {
            if (ApptyaRuntimeHud.Instance != null)
                ApptyaRuntimeHud.Instance.SelectBuilding(buildingKey, displayName);
        }
    }
}