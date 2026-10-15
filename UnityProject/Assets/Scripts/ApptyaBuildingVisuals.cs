using UnityEngine;

namespace ApptyaKingdom
{
    /// <summary>Shows saved upgrade levels on the procedural kingdom buildings.</summary>
    public class ApptyaBuildingVisuals : MonoBehaviour
    {
        ApptyaGameState state;
        readonly string[] keys = { "lumber", "farm", "barracks", "quarry" };
        readonly string[] names = { "Lumber Camp", "Farmstead", "Barracks", "Quarry" };
        readonly Vector3[] centers =
        {
            new Vector3(-8, .25f, 1), new Vector3(8, .25f, 1),
            new Vector3(-7, .25f, 7), new Vector3(7, .25f, 7)
        };
        readonly GameObject[][] markers = new GameObject[4][];
        Material goldMat, slateMat, bronzeMat, crimsonMat;
        Transform cachedRoot;

        void Start()
        {
            state = ApptyaGameState.Instance;
            cachedRoot = transform;
            var shader = Shader.Find("Universal Render Pipeline/Lit");
            if (shader == null) shader = Shader.Find("Standard");
            goldMat = new Material(shader) { color = new Color(.98f, .72f, .22f) };
            slateMat = new Material(shader) { color = new Color(.12f, .22f, .35f) };
            bronzeMat = new Material(shader) { color = new Color(.53f, .29f, .12f) };
            crimsonMat = new Material(shader) { color = new Color(.55f, .07f, .09f) };

            for (int i = 0; i < 4; i++)
            {
                markers[i] = new GameObject[4];
                for (int j = 0; j < 4; j++)
                {
                    var marker = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    marker.name = names[i] + " level crest " + (j + 2);
                    marker.transform.SetParent(cachedRoot, true);
                    marker.transform.localScale = new Vector3(.22f, .22f, .08f);
                    marker.GetComponent<Renderer>().sharedMaterial = goldMat;
                    var collider = marker.GetComponent<Collider>();
                    if (collider) Destroy(collider);
                }
            }

            if (state != null) state.Changed += Refresh;
            Refresh();
        }

        void OnDestroy()
        {
            if (state != null) state.Changed -= Refresh;
        }

        void Refresh()
        {
            if (state == null || state.Data == null || markers[0] == null) return;
            for (int i = 0; i < 4; i++)
            {
                int level = state.GetBuildingLevel(keys[i]);
                var walls = FindNamed(names[i] + " walls");
                if (walls) walls.transform.localScale = new Vector3(2.7f, 1.6f + (level - 1) * .18f, 2.3f);

                var roofL = FindNamed(names[i] + " sloped roof left");
                var roofR = FindNamed(names[i] + " sloped roof right");
                if (roofL) roofL.transform.localScale = new Vector3(1.75f + (level - 1) * .12f, .24f, 2.85f);
                if (roofR) roofR.transform.localScale = new Vector3(1.75f + (level - 1) * .12f, .24f, 2.85f);

                for (int j = 0; j < 4; j++)
                {
                    var marker = markers[i][j];
                    marker.SetActive(j < level - 1);
                    marker.transform.position = centers[i] + new Vector3((j - 1.5f) * .3f, 2.95f, -1.38f);
                }

                var ridge = FindNamed(names[i] + " roof ridge");
                if (ridge) ridge.GetComponent<Renderer>().sharedMaterial = level >= 4 ? goldMat : level >= 3 ? bronzeMat : slateMat;

                var door = FindNamed(names[i] + " front door");
                if (door && level >= 5) door.GetComponent<Renderer>().sharedMaterial = goldMat;
            }

            int keepLevel = state.Data.keepLevel;
            var hall = FindNamed("Keep hall");
            if (hall)
            {
                hall.transform.localScale = new Vector3(5.2f + (keepLevel - 1) * .12f,
                    3.3f + (keepLevel - 1) * .22f, 4.3f + (keepLevel - 1) * .10f);
                hall.GetComponent<Renderer>().sharedMaterial = keepLevel >= 7 ? goldMat : keepLevel >= 4 ? bronzeMat : slateMat;
            }

            var gate = FindNamed("Keep gate");
            if (gate && keepLevel >= 5) gate.GetComponent<Renderer>().sharedMaterial = goldMat;
            var royalBanner = FindNamed("Royal banner");
            if (royalBanner)
                royalBanner.GetComponent<Renderer>().sharedMaterial = keepLevel >= 8 ? goldMat : crimsonMat;

            // Enemy outpost becomes visually more threatening as the campaign advances.
            var enemyRoof = FindNamed("Enemy outpost roof");
            if (enemyRoof)
            {
                enemyRoof.transform.localScale = new Vector3(3.3f + (state.Data.enemyLevel - 1) * .12f,
                    .3f, 2.6f + (state.Data.enemyLevel - 1) * .08f);
                enemyRoof.GetComponent<Renderer>().sharedMaterial = state.Data.enemyLevel >= 5 ? crimsonMat : slateMat;
            }
            var enemyBanner = FindNamed("Enemy banner");
            if (enemyBanner)
                enemyBanner.GetComponent<Renderer>().sharedMaterial = state.Data.enemyLevel >= 5 ? crimsonMat : bronzeMat;
        }

        GameObject FindNamed(string name)
        {
            var all = cachedRoot.GetComponentsInChildren<Transform>(true);
            foreach (var child in all)
                if (child.name == name) return child.gameObject;
            return null;
        }
    }
}