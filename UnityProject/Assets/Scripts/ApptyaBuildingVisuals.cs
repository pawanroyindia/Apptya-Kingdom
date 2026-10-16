using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

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
        Dictionary<string, GameObject> namedObjects;
        readonly GameObject[] guardMarkers = new GameObject[25];
        readonly Vector3[] guardHomePositions = new Vector3[25];
        float troopMotionClock;
        Transform practiceTarget;

        void Start()
        {
            state = ApptyaGameState.Instance;
            cachedRoot = transform;
            bool urpActive = GraphicsSettings.currentRenderPipeline != null;
            var shader = Shader.Find(urpActive ? "Universal Render Pipeline/Lit" : "Standard");
            if (shader == null) shader = Shader.Find(urpActive ? "Standard" : "Universal Render Pipeline/Lit");
            if (shader == null) { Debug.LogError("Apptya Kingdom: no compatible shader found for building visuals."); enabled = false; return; }
            goldMat = new Material(shader) { color = new Color(.98f, .72f, .22f) };
            slateMat = new Material(shader) { color = new Color(.12f, .22f, .35f) };
            bronzeMat = new Material(shader) { color = new Color(.53f, .29f, .12f) };
            crimsonMat = new Material(shader) { color = new Color(.55f, .07f, .09f) };

            // A small visible squad makes training and battle losses readable in the world.
            for (int i = 0; i < guardMarkers.Length; i++)
            {
                var guard = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                guard.name = "Kingdom guard " + (i + 1);
                guard.transform.SetParent(cachedRoot, true);
                guard.transform.localScale = new Vector3(.38f, .55f, .38f);
                guard.GetComponent<Renderer>().sharedMaterial = bronzeMat;
                var collider = guard.GetComponent<Collider>();
                if (collider) Destroy(collider);
                guardMarkers[i] = guard;
            }

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

            CreatePracticeTarget();
            if (state != null) state.Changed += Refresh;
            Refresh();
        }

        void CreatePracticeTarget()
        {
            var root = new GameObject("Visible Practice Target").transform;
            root.SetParent(cachedRoot, false);
            root.position = new Vector3(10f, 0f, -7f);
            practiceTarget = root;
            var tap = root.gameObject.AddComponent<ApptyaBuildingTap>();
            tap.Configure("practice", "Practice Target");

            var ring = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            ring.name = "Practice target ground ring";
            ring.transform.SetParent(root, false);
            ring.transform.localPosition = new Vector3(0f, .08f, 0f);
            ring.transform.localScale = new Vector3(1.65f, .06f, 1.65f);
            ring.GetComponent<Renderer>().sharedMaterial = goldMat;
            var ringCollider = ring.GetComponent<Collider>();
            if (ringCollider) Destroy(ringCollider);

            var dummy = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            dummy.name = "Practice target dummy";
            dummy.transform.SetParent(root, false);
            dummy.transform.localPosition = new Vector3(0f, .9f, 0f);
            dummy.transform.localScale = new Vector3(.48f, .85f, .48f);
            dummy.GetComponent<Renderer>().sharedMaterial = crimsonMat;
            var dummyCollider = dummy.GetComponent<Collider>();
            if (dummyCollider) Destroy(dummyCollider);

            var crossbar = GameObject.CreatePrimitive(PrimitiveType.Cube);
            crossbar.name = "Practice target crossbar";
            crossbar.transform.SetParent(root, false);
            crossbar.transform.localPosition = new Vector3(0f, 1.1f, 0f);
            crossbar.transform.localScale = new Vector3(1.05f, .12f, .16f);
            crossbar.GetComponent<Renderer>().sharedMaterial = goldMat;
            var crossCollider = crossbar.GetComponent<Collider>();
            if (crossCollider) Destroy(crossCollider);
        }

        void Update()
        {
            troopMotionClock += Time.deltaTime;
            if (practiceTarget != null) practiceTarget.localScale = Vector3.one * (1f + Mathf.Sin(troopMotionClock * 1.7f) * .025f);
            for (int i = 0; i < guardMarkers.Length; i++)
            {
                var guard = guardMarkers[i];
                if (guard == null || !guard.activeSelf) continue;
                var p = guardHomePositions[i];
                guard.transform.position = p + Vector3.up * (Mathf.Sin(troopMotionClock * 2.2f + i * .73f) * .045f);
                guard.transform.rotation = Quaternion.Euler(0f, Mathf.Sin(troopMotionClock * 1.1f + i) * 4f, 0f);
            }
        }

        void OnDestroy()
        {
            if (state != null) state.Changed -= Refresh;
            if (goldMat) Destroy(goldMat);
            if (slateMat) Destroy(slateMat);
            if (bronzeMat) Destroy(bronzeMat);
            if (crimsonMat) Destroy(crimsonMat);
        }

        void Refresh()
        {
            if (state == null || state.Data == null || markers[0] == null) return;
            for (int i = 0; i < guardMarkers.Length; i++)
            {
                bool visible = i < Mathf.Min(state.Data.guards, guardMarkers.Length);
                guardMarkers[i].SetActive(visible);
                var troopRenderer = guardMarkers[i].GetComponent<Renderer>();
                if (troopRenderer)
                    troopRenderer.sharedMaterial = i < state.Data.infantry ? bronzeMat :
                        i < state.Data.infantry + state.Data.archers ? goldMat :
                        i < state.Data.infantry + state.Data.archers + state.Data.cavalry ? crimsonMat : bronzeMat;
                int column = i % 5;
                int row = i / 5;
                guardHomePositions[i] = new Vector3(-9.2f + column * 1.1f, .55f, 9.4f + row * .9f);
                guardMarkers[i].transform.position = guardHomePositions[i];
            }

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
                if (ridge) ridge.GetComponent<Renderer>().sharedMaterial = state.IsUpgradeActive(keys[i]) ? goldMat : level >= 4 ? goldMat : level >= 3 ? bronzeMat : slateMat;

                var door = FindNamed(names[i] + " front door");
                if (door && level >= 5) door.GetComponent<Renderer>().sharedMaterial = goldMat;
            }

            int keepLevel = state.Data.keepLevel;
            var hall = FindNamed("Keep hall");
            if (hall)
            {
                hall.transform.localScale = new Vector3(5.2f + (keepLevel - 1) * .12f,
                    3.3f + (keepLevel - 1) * .22f, 4.3f + (keepLevel - 1) * .10f);
                hall.GetComponent<Renderer>().sharedMaterial = state.IsUpgradeActive("keep") ? goldMat : keepLevel >= 7 ? goldMat : keepLevel >= 4 ? bronzeMat : slateMat;
            }

            var gate = FindNamed("Keep gate");
            if (gate && keepLevel >= 5) gate.GetComponent<Renderer>().sharedMaterial = goldMat;
            var royalBanner = FindNamed("Royal banner");
            if (royalBanner)
                royalBanner.GetComponent<Renderer>().sharedMaterial = keepLevel >= 8 ? goldMat : crimsonMat;

            // Visual threat scaling is deliberately capped: gameplay enemy levels can reach
            // 100,000, but allowing that value to scale a mesh would create kilometre-sized art.
            int visualThreatTier = Mathf.Clamp(state.Data.enemyLevel, 1, 12);
            var enemyRoof = FindNamed("Enemy outpost roof");
            if (enemyRoof)
            {
                enemyRoof.transform.localScale = new Vector3(3.3f + (visualThreatTier - 1) * .12f,
                    .3f, 2.6f + (visualThreatTier - 1) * .08f);
                enemyRoof.GetComponent<Renderer>().sharedMaterial = visualThreatTier >= 5 ? crimsonMat : slateMat;
            }
            var enemyBanner = FindNamed("Enemy banner");
            if (enemyBanner)
                enemyBanner.GetComponent<Renderer>().sharedMaterial = state.Data.enemyLevel >= 5 ? crimsonMat : bronzeMat;
        }

        GameObject FindNamed(string name)
        {
            if (namedObjects == null)
            {
                namedObjects = new Dictionary<string, GameObject>();
                var all = cachedRoot.GetComponentsInChildren<Transform>(true);
                foreach (var child in all)
                    if (!namedObjects.ContainsKey(child.name))
                        namedObjects.Add(child.name, child.gameObject);
            }
            GameObject found;
            if (namedObjects.TryGetValue(name, out found) && found != null) return found;

            // The procedural scene builder and this visual component can start in either
            // order. If the first lookup happened before a building was created, refresh
            // the cache so a later state change can still find that building.
            var all = cachedRoot.GetComponentsInChildren<Transform>(true);
            foreach (var child in all)
                if (!namedObjects.ContainsKey(child.name))
                    namedObjects.Add(child.name, child.gameObject);
            return namedObjects.TryGetValue(name, out found) ? found : null;
        }
    }
}