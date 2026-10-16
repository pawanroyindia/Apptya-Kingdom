#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ApptyaKingdom.EditorTools
{
    /// <summary>
    /// Non-interactive cloud build entry point. Creates the starter scene if missing,
    /// preserves other enabled build scenes, and produces a signed-by-Unity debug APK.
    /// This does not configure release signing.
    /// </summary>
    public static class ApptyaAndroidBuild
    {
        private const string ScenePath = "Assets/Scenes/ApptyaKingdom.unity";
        private const string PackageId = "com.apptya.kingdom";
        private const string OutputPath = "Build/Android/ApptyaKingdom.apk";

        public static void BuildAndroidApk()
        {
            try
            {
                EnsureStarterScene();
                EnsureAndroidBuildTarget();

                PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, PackageId);
                PlayerSettings.defaultInterfaceOrientation = UIOrientation.Portrait;
                PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
                PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevel36;
                PlayerSettings.bundleVersion = "0.1.0";
                PlayerSettings.Android.useCustomKeystore = false;

                string output = Path.GetFullPath(OutputPath);
                Directory.CreateDirectory(Path.GetDirectoryName(output));

                var scenes = new List<string>();
                foreach (var scene in EditorBuildSettings.scenes)
                    if (scene.enabled) scenes.Add(scene.path);

                if (scenes.Count == 0 || !scenes.Contains(ScenePath))
                    throw new InvalidOperationException("Starter scene is not enabled in Build Settings.");

                var options = new BuildPlayerOptions
                {
                    scenes = scenes.ToArray(),
                    locationPathName = output,
                    target = BuildTarget.Android,
                    options = BuildOptions.None
                };

                BuildReport report = BuildPipeline.BuildPlayer(options);
                string summary = "Result: " + report.summary.result +
                    "\nErrors: " + report.summary.totalErrors +
                    "\nWarnings: " + report.summary.totalWarnings +
                    "\nOutput: " + output +
                    "\nPackage ID: " + PackageId +
                    "\nUnity: " + Application.unityVersion +
                    "\nTarget: Android API 36 (ARM64)";

                Directory.CreateDirectory("Build");
                File.WriteAllText("Build/android-build-report.txt", summary + "\n");
                Debug.Log("[Apptya Android Build] " + summary);

                if (report.summary.result != BuildResult.Succeeded)
                    throw new InvalidOperationException("Android BuildPipeline result was " + report.summary.result + ".");

                if (!File.Exists(output) || new FileInfo(output).Length == 0)
                    throw new FileNotFoundException("Unity reported success but the APK is missing or empty.", output);

                File.WriteAllText("Build/android-build-report.txt", summary +
                    "\nAPK bytes: " + new FileInfo(output).Length + "\nAPK existence check: PASS\n");
            }
            catch (Exception exception)
            {
                Debug.LogException(exception);
                Directory.CreateDirectory("Build");
                File.WriteAllText("Build/android-build-report.txt",
                    "Result: FAILED\nUnity: " + Application.unityVersion + "\n" + exception);
                throw;
            }
        }

        private static void EnsureAndroidBuildTarget()
        {
            if (EditorUserBuildSettings.activeBuildTarget != BuildTarget.Android)
            {
                bool switched = EditorUserBuildSettings.SwitchActiveBuildTarget(
                    BuildTargetGroup.Android, BuildTarget.Android);
                if (!switched)
                    throw new InvalidOperationException(
                        "Could not switch Unity to Android. Confirm Android Build Support is installed.");
            }
        }

        private static void EnsureStarterScene()
        {
            if (!AssetDatabase.IsValidFolder("Assets/Scenes"))
                AssetDatabase.CreateFolder("Assets", "Scenes");

            if (AssetDatabase.LoadAssetAtPath<SceneAsset>(ScenePath) == null)
            {
                Scene scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                var root = new GameObject("Apptya Kingdom Bootstrap");
                root.AddComponent<ApptyaKingdom.ProceduralKingdomBootstrap>();
                EditorSceneManager.MarkSceneDirty(scene);
                if (!EditorSceneManager.SaveScene(scene, ScenePath))
                    throw new InvalidOperationException("Failed to save generated starter scene.");
            }

            var buildScenes = new List<EditorBuildSettingsScene>(EditorBuildSettings.scenes);
            int index = buildScenes.FindIndex(item => item.path == ScenePath);
            var entry = new EditorBuildSettingsScene(ScenePath, true);
            if (index >= 0) buildScenes[index] = entry;
            else buildScenes.Add(entry);
            EditorBuildSettings.scenes = buildScenes.ToArray();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
    }
}
#endif
