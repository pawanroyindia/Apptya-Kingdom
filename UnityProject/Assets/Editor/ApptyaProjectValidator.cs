#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Rendering;

namespace ApptyaKingdom.EditorTools
{
    /// <summary>Source-level project preflight. Reports setup issues without building an APK.</summary>
    public static class ApptyaProjectValidator
    {
        private const string ScenePath = "Assets/Scenes/ApptyaKingdom.unity";

        [MenuItem("Apptya Kingdom/Validate Project")]
        public static void ValidateProject()
        {
            var errors = new List<string>();
            var warnings = new List<string>();

            CheckAsset<MonoScript>("Assets/Scripts/ApptyaGameState.cs", errors);
            CheckAsset<MonoScript>("Assets/Scripts/ProceduralKingdomBootstrap.cs", errors);
            CheckAsset<MonoScript>("Assets/Scripts/ApptyaRuntimeHud.cs", errors);
            CheckAsset<MonoScript>("Assets/Scripts/ApptyaCameraController.cs", errors);
            CheckAsset<MonoScript>("Assets/Scripts/ApptyaBuildingVisuals.cs", errors);
            CheckAsset<MonoScript>("Assets/Scripts/ApptyaBuildingTap.cs", errors);
            CheckAsset<MonoScript>("Assets/Editor/ApptyaProjectSetup.cs", errors);

            if (!AssetDatabase.IsValidFolder("Assets/Scenes"))
                errors.Add("Assets/Scenes folder is missing. Run Apptya Kingdom > Setup Starter Scene.");
            if (!AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath))
                errors.Add("Starter scene is missing. Run Apptya Kingdom > Setup Starter Scene.");

            bool sceneInBuild = false;
            foreach (var scene in EditorBuildSettings.scenes)
                if (scene.enabled && scene.path == ScenePath) sceneInBuild = true;
            if (!sceneInBuild)
                warnings.Add("Starter scene is not enabled in Build Settings.");

            if (GraphicsSettings.defaultRenderPipeline == null)
                warnings.Add("No Scriptable Render Pipeline asset is assigned in Project Settings > Graphics. Runtime materials will use the built-in Standard shader fallback; assign a URP asset if URP rendering is intended.");
            if (PlayerSettings.defaultInterfaceOrientation != UIOrientation.Portrait)
                warnings.Add("Player orientation is not Portrait; the current HUD was designed for portrait screens.");

            Debug.Log("Apptya Kingdom preflight: " + errors.Count + " error(s), " + warnings.Count + " warning(s).");
            foreach (var warning in warnings) Debug.LogWarning("[Apptya Kingdom] " + warning);
            foreach (var error in errors) Debug.LogError("[Apptya Kingdom] " + error);

            string report = "Preflight complete.\nErrors: " + errors.Count + "\nWarnings: " + warnings.Count +
                "\n\n" + (errors.Count == 0 ? "No required source/scene checks failed." : string.Join("\n", errors.ToArray())) +
                (warnings.Count == 0 ? "" : "\n\nWarnings:\n" + string.Join("\n", warnings.ToArray())) +
                "\n\nThis check does not compile scripts, run gameplay, test a device, or build an APK.";
            EditorUtility.DisplayDialog("Apptya Kingdom — Project Preflight", report, "OK");
        }

        private static void CheckAsset<T>(string path, List<string> errors) where T : Object
        {
            if (AssetDatabase.LoadAssetAtPath<T>(path) == null)
                errors.Add("Required project asset is missing: " + path);
        }
    }
}
#endif
