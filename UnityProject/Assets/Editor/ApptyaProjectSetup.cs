#if UNITY_EDITOR
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
            if (!AssetDatabase.IsValidFolder("Assets/Scenes"))
                AssetDatabase.CreateFolder("Assets", "Scenes");

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var root = new GameObject("Apptya Kingdom Bootstrap");
            root.AddComponent<ApptyaKingdom.ProceduralKingdomBootstrap>();

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            EditorBuildSettings.scenes = new[]
            {
                new EditorBuildSettingsScene(ScenePath, true)
            };

            AssetDatabase.SaveAssets();
            Debug.Log("Apptya Kingdom starter scene created. Press Play to test the blockout.");
            EditorUtility.DisplayDialog(
                "Apptya Kingdom",
                "Starter scene created and added to Build Settings. This is a gameplay blockout, not final art.",
                "OK");
        }
    }
}
#endif