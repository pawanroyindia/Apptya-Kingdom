#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ApptyaKingdom.EditorTools
{
    public static class ApptyaProjectSetup
    {
        private const string ScenePath = "Assets/Scenes/ApptyaKingdom.unity";

        [MenuItem("Apptya Kingdom/Setup Starter Scene")]
        public static void SetupStarterScene()
        {
            bool sceneAlreadyExists = AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath) != null;
            if (sceneAlreadyExists && !EditorUtility.DisplayDialog(
                    "Replace Starter Scene?",
                    "This will replace the existing Apptya Kingdom starter scene. Other scenes and Build Settings entries will be preserved.",
                    "Replace Scene",
                    "Cancel"))
                return;

            if (!AssetDatabase.IsValidFolder("Assets/Scenes"))
                AssetDatabase.CreateFolder("Assets", "Scenes");

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var root = new GameObject("Apptya Kingdom Bootstrap");
            root.AddComponent<ApptyaKingdom.ProceduralKingdomBootstrap>();

            EditorSceneManager.MarkSceneDirty(scene);
            if (!EditorSceneManager.SaveScene(scene, ScenePath))
            {
                Debug.LogError("[Apptya Kingdom] Starter scene was not saved. Build Settings were left unchanged.");
                return;
            }

            // Add or enable the starter scene without deleting the project's other scene entries.
            var scenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            int existingIndex = scenes.FindIndex(item => item.path == ScenePath);
            var starterEntry = new EditorBuildSettingsScene(ScenePath, true);
            if (existingIndex >= 0)
                scenes[existingIndex] = starterEntry;
            else
                scenes.Add(starterEntry);
            EditorBuildSettings.scenes = scenes.ToArray();

            AssetDatabase.SaveAssets();
            Debug.Log("[Apptya Kingdom] Starter scene created and added to Build Settings; existing scene entries were preserved.");
            EditorUtility.DisplayDialog(
                "Apptya Kingdom",
                "Starter scene created and enabled in Build Settings. Other scene entries were preserved. This is a gameplay blockout, not final art.",
                "OK");
        }
    }
}
#endif
