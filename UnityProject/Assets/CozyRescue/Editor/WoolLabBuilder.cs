using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build.Reporting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using CozyRescue.Presentation;

namespace CozyRescue.Editor
{
    public static class WoolLabBuilder
    {
        const string Root="Assets/CozyRescue/";
        [MenuItem("WoolLab/Generate scene (preserve art settings)")]
        public static void Generate()
        {
            Directory.CreateDirectory(Root+"Scenes");Directory.CreateDirectory(Root+"Content");
            string settingsPath=Root+"Content/WoolLabSettings.asset";
            var settings=AssetDatabase.LoadAssetAtPath<WoolLabSettings>(settingsPath);
            if(settings==null){settings=ScriptableObject.CreateInstance<WoolLabSettings>();AssetDatabase.CreateAsset(settings,settingsPath);}
            settings.knitShader=Shader.Find("CozyRescue/KnitLit");settings.surfaceShader=Shader.Find("Universal Render Pipeline/Lit");BindArt(settings);
            var renderer=AssetDatabase.LoadAssetAtPath<UniversalRendererData>(Root+"Content/WoolRenderer.asset");
            if(renderer==null){renderer=ScriptableObject.CreateInstance<UniversalRendererData>();AssetDatabase.CreateAsset(renderer,Root+"Content/WoolRenderer.asset");}
            ScreenSpaceAmbientOcclusion contact=null;foreach(var feature in renderer.rendererFeatures)if(feature is ScreenSpaceAmbientOcclusion ao)contact=ao;
            if(contact==null){contact=ScriptableObject.CreateInstance<ScreenSpaceAmbientOcclusion>();contact.name="Soft textile contact";AssetDatabase.AddObjectToAsset(contact,renderer);renderer.rendererFeatures.Add(contact);}
            var contactData=new SerializedObject(contact);var contactSettings=contactData.FindProperty("m_Settings");
            contactSettings.FindPropertyRelative("Source").intValue=0;contactSettings.FindPropertyRelative("AfterOpaque").boolValue=true;contactSettings.FindPropertyRelative("Downsample").boolValue=true;
            contactSettings.FindPropertyRelative("Intensity").floatValue=.65f;contactSettings.FindPropertyRelative("Radius").floatValue=.16f;contactSettings.FindPropertyRelative("Samples").intValue=2;contactSettings.FindPropertyRelative("BlurQuality").intValue=0;
            contactData.ApplyModifiedPropertiesWithoutUndo();EditorUtility.SetDirty(renderer);
            var pipeline=AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(Root+"Content/WoolPipeline.asset");
            if(pipeline==null){pipeline=UniversalRenderPipelineAsset.Create(renderer);AssetDatabase.CreateAsset(pipeline,Root+"Content/WoolPipeline.asset");}
            pipeline.supportsHDR=false;pipeline.msaaSampleCount=2;pipeline.shadowDistance=30;pipeline.shadowCascadeCount=1;pipeline.mainLightShadowmapResolution=2048;
            var pipelineSerialized=new SerializedObject(pipeline);pipelineSerialized.FindProperty("m_SoftShadowsSupported").boolValue=true;pipelineSerialized.FindProperty("m_SoftShadowQuality").intValue=2;pipelineSerialized.ApplyModifiedPropertiesWithoutUndo();
            GraphicsSettings.defaultRenderPipeline=pipeline;QualitySettings.renderPipeline=pipeline;QualitySettings.vSyncCount=0;
            PlayerSettings.colorSpace=ColorSpace.Linear;PlayerSettings.companyName="Cozy Workshop";PlayerSettings.productName="솜길 구조대 · WoolLab";
            PlayerSettings.SetGraphicsAPIs(BuildTarget.StandaloneWindows64,new[]{GraphicsDeviceType.Direct3D11});PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.StandaloneWindows64,false);
            PlayerSettings.defaultScreenWidth=720;PlayerSettings.defaultScreenHeight=1560;PlayerSettings.fullScreenMode=FullScreenMode.Windowed;
            PlayerSettings.defaultInterfaceOrientation=UIOrientation.Portrait;PlayerSettings.allowedAutorotateToLandscapeLeft=false;PlayerSettings.allowedAutorotateToLandscapeRight=false;PlayerSettings.allowedAutorotateToPortraitUpsideDown=false;
            PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android,"com.cozyworkshop.woollab");
            PlayerSettings.Android.minSdkVersion=AndroidSdkVersions.AndroidApiLevel26;PlayerSettings.Android.targetSdkVersion=(AndroidSdkVersions)36;
            PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64;
            PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);
            PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,new[]{GraphicsDeviceType.OpenGLES3});PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android,false);
            PlayerSettings.Android.forceInternetPermission=false;PlayerSettings.Android.forceSDCardPermission=false;
            var serialized=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
            var input=serialized.FindProperty("activeInputHandler");if(input!=null){input.intValue=1;serialized.ApplyModifiedPropertiesWithoutUndo();}
            EditorUtility.SetDirty(settings);EditorUtility.SetDirty(pipeline);AssetDatabase.SaveAssets();
            var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);
            settings=AssetDatabase.LoadAssetAtPath<WoolLabSettings>(settingsPath);
            var root=new GameObject("WoolLab");var lab=root.AddComponent<WoolLab>();lab.settings=settings;
            // Presentation is generated from preserved recipes at play time; no hand-edited scene YAML.
            EditorSceneManager.SaveScene(scene,Root+"Scenes/WoolLab.unity");
            EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(Root+"Scenes/WoolLab.unity",true)};
            AssetDatabase.SaveAssets();
            Debug.Log("WOOLLAB_GENERATED Unity="+Application.unityVersion);
        }
        [MenuItem("WoolLab/Refresh original art bindings")]
        public static void RefreshArt()
        {
            var settings=AssetDatabase.LoadAssetAtPath<WoolLabSettings>(Root+"Content/WoolLabSettings.asset");if(settings){BindArt(settings);EditorUtility.SetDirty(settings);AssetDatabase.SaveAssets();}
        }
        static void BindArt(WoolLabSettings settings)
        {
            foreach(string guid in AssetDatabase.FindAssets("t:Model",new[]{Root+"Art"}))
            {
                string p=AssetDatabase.GUIDToAssetPath(guid),name=Path.GetFileNameWithoutExtension(p).ToLowerInvariant();var model=AssetDatabase.LoadAssetAtPath<GameObject>(p);
                if(name.Contains("dragon"))settings.dragonModel=model;
                else if(name.Contains("cat"))settings.catModel=model;
                else if(name.Contains("cuff")||name.Contains("segment")){var f=model.GetComponentInChildren<MeshFilter>();if(f){
                    var mesh=UnityEngine.Object.Instantiate(f.sharedMesh);mesh.name="Cloud cuff baked Unity axes";var matrix=f.transform.localToWorldMatrix;var vertices=mesh.vertices;
                    for(int i=0;i<vertices.Length;i++)vertices[i]=matrix.MultiplyPoint3x4(vertices[i]);mesh.vertices=vertices;mesh.RecalculateBounds();
                    if(mesh.bounds.size.y>mesh.bounds.size.z){var correction=Quaternion.Euler(90,0,0);for(int i=0;i<vertices.Length;i++)vertices[i]=correction*vertices[i];mesh.vertices=vertices;}
                    mesh.RecalculateNormals();mesh.RecalculateTangents();mesh.RecalculateBounds();
                    string baked=Root+"Content/CloudCuff.asset";var existing=AssetDatabase.LoadAssetAtPath<Mesh>(baked);if(existing){EditorUtility.CopySerialized(mesh,existing);UnityEngine.Object.DestroyImmediate(mesh);settings.cuffMesh=existing;}else{AssetDatabase.CreateAsset(mesh,baked);settings.cuffMesh=mesh;}
                    Debug.Log("WOOL_CUFF_BOUNDS "+settings.cuffMesh.bounds.size);
                }}
            }
            foreach(string guid in AssetDatabase.FindAssets("t:Texture2D",new[]{Root+"Art"}))
            {
                string p=AssetDatabase.GUIDToAssetPath(guid),name=Path.GetFileNameWithoutExtension(p).ToLowerInvariant();var importer=AssetImporter.GetAtPath(p) as TextureImporter;if(importer==null)continue;
                if(settings.physicalKnit&&!name.StartsWith(File.Exists(Root+"Art/Textures/RefinedKnitNormal.png")?"refinedknit":"physicalknit"))continue;
                if(!settings.physicalKnit&&name.StartsWith("physicalknit"))continue;
                if(name.Contains("normal")){importer.textureType=TextureImporterType.NormalMap;settings.knitNormal=AssetDatabase.LoadAssetAtPath<Texture2D>(p);}
                else if(name.Contains("ao")){importer.sRGBTexture=false;settings.knitAO=AssetDatabase.LoadAssetAtPath<Texture2D>(p);}
                else continue;
                importer.mipmapEnabled=true;importer.wrapMode=TextureWrapMode.Repeat;importer.anisoLevel=4;
                var android=importer.GetPlatformTextureSettings("Android");android.overridden=true;android.format=TextureImporterFormat.ASTC_6x6;android.maxTextureSize=1024;importer.SetPlatformTextureSettings(android);importer.SaveAndReimport();
            }
            string[] icons={"pause","replay","speed"};settings.controlIcons=new Sprite[3];
            for(int i=0;i<3;i++){string iconPath=Root+"Art/UI/control_"+icons[i]+".png";var importer=AssetImporter.GetAtPath(iconPath) as TextureImporter;if(importer!=null){importer.textureType=TextureImporterType.Sprite;importer.spriteImportMode=SpriteImportMode.Single;importer.mipmapEnabled=false;importer.alphaIsTransparency=true;importer.SaveAndReimport();settings.controlIcons[i]=AssetDatabase.LoadAssetAtPath<Sprite>(iconPath);}}
            foreach(string guid in AssetDatabase.FindAssets("t:Font",new[]{Root+"Art"})){settings.uiFont=AssetDatabase.LoadAssetAtPath<Font>(AssetDatabase.GUIDToAssetPath(guid));break;}
        }
        public static void ApplyVisualReview(){var settings=AssetDatabase.LoadAssetAtPath<WoolLabSettings>(Root+"Content/WoolLabSettings.asset");settings.bodyWidth=1.4f;settings.bodyPitch=.45f;settings.stitchColumns=12;EditorUtility.SetDirty(settings);AssetDatabase.SaveAssets();BuildWindows();}
        [MenuItem("WoolLab/Build Windows preview")]
        public static void BuildWindows(){Generate();Build(BuildTarget.StandaloneWindows64,"../Builds/Windows/WoolLab.exe",BuildOptions.None);}
        [MenuItem("WoolLab/Build Android APK")]
        public static void BuildAndroid(){Generate();Build(BuildTarget.Android,"../Builds/Android/WoolLab.apk",BuildOptions.None);}
        static void Build(BuildTarget target,string output,BuildOptions options)
        {
            output=Path.GetFullPath(Path.Combine(Application.dataPath,"..",output));Directory.CreateDirectory(Path.GetDirectoryName(output));
            var result=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{Root+"Scenes/WoolLab.unity"},locationPathName=output,target=target,options=options});
            Debug.Log("WOOL_BUILD "+target+" "+result.summary.result+" bytes="+result.summary.totalSize);
            if(result.summary.result!=BuildResult.Succeeded)throw new Exception("WoolLab build failed: "+result.summary.result);
        }
    }
}


