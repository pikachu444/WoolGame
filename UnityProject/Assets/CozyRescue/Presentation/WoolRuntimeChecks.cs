using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace CozyRescue.Presentation
{
    /// <summary>Explicit opt-in integration checks. Never attached during ordinary play.</summary>
    public sealed class WoolRuntimeChecks : MonoBehaviour
    {
        [Serializable] public sealed class Check { public string name; public bool passed; public string detail; }
        [Serializable] public sealed class Report
        {
            public string scope="Actual player API integration; not physical touch, visual acceptance, or Android performance certification.";
            public string platform, unity, device, graphics, timestampUtc;
            public bool passed;
            public int runtimeErrors, frameSamples, replayIterations;
            public float sampleWallSeconds, frameMedianMs, frameP95Ms;
            public string performanceScope="Five-second noncapture wall-frame sample while playing; includes check-runner overhead. No GPU timing or 15-minute stability claim.";
            public Check[] checks;
        }
        readonly List<Check> checks=new List<Check>();
        readonly List<float> frameTimes=new List<float>(1200);
        int errors,replays;
        bool finalized;
        float sampleWallSeconds;
        string outputDirectory;
        bool quit;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Install()
        {
            string[] args=Environment.GetCommandLineArgs();
            if(Array.IndexOf(args,"--wool-checks")<0)return;
            var go=new GameObject("Opt-in WoolLab runtime checks");
            go.AddComponent<WoolRuntimeChecks>();
        }
        void OnEnable(){Application.logMessageReceived+=OnLog;}
        void OnDisable(){Application.logMessageReceived-=OnLog;}
        void OnLog(string condition,string trace,LogType type)
        {if(type==LogType.Exception||type==LogType.Error||type==LogType.Assert)errors++;}
        void Record(string name,bool passed,string detail="")
        {checks.Add(new Check{name=name,passed=passed,detail=detail});}

        IEnumerator Start()
        {
            string[] args=Environment.GetCommandLineArgs();
            outputDirectory=Application.persistentDataPath;quit=Array.IndexOf(args,"--wool-quit")>=0;
            for(int i=0;i<args.Length-1;i++)if(args[i]=="--wool-checks-dir")outputDirectory=args[i+1];
            yield return null;
            var lab=FindFirstObjectByType<WoolLab>();
            if(lab==null||lab.Session==null){Record("Scene contains initialized WoolLab",false);Finish();yield break;}
            if(Array.IndexOf(args,"--wool-demo")>=0||Array.IndexOf(args,"--wool-capture")>=0)
            {
                lab.automaticDemo=false;
                Record("Exclusive runtime-check mode",false,"Do not combine --wool-checks with --wool-demo or --wool-capture.");
                Finish();yield break;
            }
            lab.automaticDemo=false;lab.playbackSpeed=1;lab.Replay();
            Record("Blocked B rejects",!lab.Select(1)&&lab.Session.ConsumedCount==0&&lab.Session.Blocks[1].Slot==-1);
            Record("Select D",lab.Select(3));
            Record("Select C",lab.Select(2));
            Record("Select B",lab.Select(1));
            Record("Select A",lab.Select(0));
            yield return null;
            lab.TogglePause();float pausedTime=lab.Session.Time;int pausedCount=lab.Session.ConsumedCount;
            float pauseBegin=Time.realtimeSinceStartup;
            while(Time.realtimeSinceStartup-pauseBegin<.25f)yield return null;
            Record("Pause freezes clock and collection for .25 wall seconds",lab.Session.Paused&&lab.Session.Time==pausedTime&&lab.Session.ConsumedCount==pausedCount);
            lab.TogglePause();Record("Resume clears pause",!lab.Session.Paused);
            float started=Time.realtimeSinceStartup,previous=started;
            while(Time.realtimeSinceStartup-started<10)
            {
                yield return null;
                float now=Time.realtimeSinceStartup;
                if(now-started<=5){frameTimes.Add((now-previous)*1000);sampleWallSeconds=now-started;}
                previous=now;
                if(lab.Session.Won&&now-started>=5)break;
            }
            Record("24 units collected and success within 10 seconds",lab.Session.Won&&lab.Session.ConsumedCount==24);
            float wonTime=lab.Session.Time;
            yield return null;
            Record("Clock continues after logical success",lab.Session.Time>wonTime);
            // Allow the normal presentation update to run through final winding and rescue.
            float effectStart=Time.realtimeSinceStartup;
            while(Time.realtimeSinceStartup-effectStart<1.8f)yield return null;

            bool allReplays=true;
            for(int iteration=0;iteration<20;iteration++)
            {
                int oldRevision=lab.Session.Revision;lab.Replay();
                bool ok=lab.Session.Revision==oldRevision+1&&!lab.Session.Won&&lab.Session.ConsumedCount==0;
                for(int id=3;id>=0;id--)ok=lab.Select(id)&&ok;
                // Deterministic state advance; the following real player frame updates presentation.
                lab.Session.Advance(6);yield return null;
                ok=ok&&lab.Session.Won&&lab.Session.ConsumedCount==24;
                allReplays=allReplays&&ok;replays++;
            }
            Record("Twenty replay cycles",allReplays,"API-driven resets and deterministic advances, with a real presentation frame after every cycle.");
            if(Array.IndexOf(args,"--wool-aspects")>=0)yield return CheckAspects(lab);
            Record("No runtime errors during checks",errors==0,"Error/exception/assert log count: "+errors);
            lab.Replay();yield return null;
            Finish();
        }
        IEnumerator CheckAspects(WoolLab lab)
        {
            int[] heights={800,1000,975};
            string[] names={"16_9","20_9","19_5_9"};
            lab.Replay();
            int originalWidth=Screen.width,originalHeight=Screen.height;
            var baselineOwned=SnapshotOwnedAssets(lab);
            string baselineCounts=AssetCounts(baselineOwned);
            Record("Owned resource tracker available",baselineOwned!=null&&baselineOwned.Length>0);
            for(int i=0;i<heights.Length;i++)
            {
                if(!lab.Session.Paused)lab.TogglePause();
                float time=lab.Session.Time;int consumed=lab.Session.ConsumedCount;
                Screen.SetResolution(450,heights[i],FullScreenMode.Windowed);
                yield return WaitForResize();
                Record("Paused aspect resize "+names[i],lab.Session.Paused&&lab.Session.Time==time&&lab.Session.ConsumedCount==consumed,
                    "Requested 450x"+heights[i]+"; actual "+Screen.width+"x"+Screen.height+". API resize, not physical touch.");
                Record("Aspect dimensions "+names[i],Screen.width==450&&Screen.height==heights[i],"Actual "+Screen.width+"x"+Screen.height);
                lab.TogglePause();
                yield return new WaitForEndOfFrame();
                CaptureAspect("aspect_"+names[i]+".png");
            }
            lab.Replay();lab.Select(3);lab.Session.Advance(1.2f);
            yield return null;
            lab.TogglePause();float unwindTime=lab.Session.Time;int unwindCount=lab.Session.ConsumedCount;
            Screen.SetResolution(450,800,FullScreenMode.Windowed);
            yield return WaitForResize();
            Record("Mid-unravel paused resize preserves clock and collection",lab.Session.Paused&&lab.Session.Time==unwindTime&&lab.Session.ConsumedCount==unwindCount,
                "Session seconds="+lab.Session.Time+"; consumed="+lab.Session.ConsumedCount+"; actual "+Screen.width+"x"+Screen.height);
            int activeUnits=0,originUnits=0;
            foreach(var part in lab.GetComponentsInChildren<Transform>())
                if(part.gameObject.activeInHierarchy&&part.name.StartsWith("Knit unit ",StringComparison.Ordinal))
                {activeUnits++;if(part.position.sqrMagnitude<.0001f)originUnits++;}
            Record("Mid-unravel units do not collapse to world origin",activeUnits>0&&originUnits==0,
                "Active knit transforms="+activeUnits+"; at origin="+originUnits+". Geometry sanity only; visual continuity requires image review.");
            yield return new WaitForEndOfFrame();
            CaptureAspect("aspect_mid_unravel_paused.png");
            if(lab.Session.Paused)lab.TogglePause();
            // Return to the baseline aspect and allow deferred Destroy calls to finish.
            lab.TogglePause();
            Screen.SetResolution(originalWidth,originalHeight,FullScreenMode.Windowed);
            yield return WaitForResize();
            yield return null;yield return null;
            var currentOwned=SnapshotOwnedAssets(lab);
            int oldStillAlive=0;
            if(baselineOwned!=null)foreach(var asset in baselineOwned)if(asset)oldStillAlive++;
            bool sameAspect=Screen.width==originalWidth&&Screen.height==originalHeight;
            Record("Owned resources replaced without retained old assets",
                sameAspect&&baselineOwned!=null&&currentOwned!=null&&baselineOwned.Length==currentOwned.Length&&oldStillAlive==0,
                "Returned aspect="+Screen.width+"x"+Screen.height+"; baseline owned="+(baselineOwned==null?-1:baselineOwned.Length)+
                "; current owned="+(currentOwned==null?-1:currentOwned.Length)+"; old native objects alive="+oldStillAlive+
                ". Before: "+baselineCounts+". After: "+AssetCounts(currentOwned)+
                ". Global counts are diagnostic only; imported/builtin resource activity is not an exact-count gate.");
            lab.TogglePause();
        }
        static UnityEngine.Object[] SnapshotOwnedAssets(WoolLab lab)
        {
            var field=typeof(WoolLab).GetField("ownedPresentationAssets",System.Reflection.BindingFlags.Instance|System.Reflection.BindingFlags.NonPublic);
            var assets=field==null?null:field.GetValue(lab) as List<UnityEngine.Object>;
            return assets==null?null:assets.ToArray();
        }
        static string AssetCounts(UnityEngine.Object[] owned)
        {
            int ownedMeshes=0,ownedMaterials=0,ownedTextures=0;
            if(owned!=null)foreach(var asset in owned)
            {if(asset is Mesh)ownedMeshes++;else if(asset is Material)ownedMaterials++;else if(asset is Texture)ownedTextures++;}
            return "owned meshes/materials/textures="+ownedMeshes+"/"+ownedMaterials+"/"+ownedTextures+
                "; global loaded meshes/materials="+Resources.FindObjectsOfTypeAll<Mesh>().Length+"/"+Resources.FindObjectsOfTypeAll<Material>().Length;
        }
        IEnumerator WaitForResize()
        {
            for(int frame=0;frame<3;frame++)yield return null;
            float begin=Time.realtimeSinceStartup;
            while(Time.realtimeSinceStartup-begin<.15f)yield return null;
        }
        void CaptureAspect(string filename)
        {
            Texture2D screenshot=null;
            try
            {
                screenshot=ScreenCapture.CaptureScreenshotAsTexture();
                if(screenshot==null){Record("Capture "+filename,false,"ScreenCapture returned null.");return;}
                Directory.CreateDirectory(outputDirectory);
                byte[] bytes=screenshot.EncodeToPNG();
                if(bytes==null||bytes.Length==0){Record("Capture "+filename,false,"PNG encoder returned no data.");return;}
                File.WriteAllBytes(Path.Combine(outputDirectory,filename),bytes);
                Record("Capture "+filename,true,"Actual runtime render "+screenshot.width+"x"+screenshot.height+"; not a desktop mouse-input check.");
            }
            catch(Exception exception){Record("Capture "+filename,false,exception.Message);}
            finally{if(screenshot!=null)Destroy(screenshot);}
        }
        void Finish()
        {
            if(finalized)return;finalized=true;
            frameTimes.Sort();bool passed=errors==0;
            foreach(var check in checks)passed=passed&&check.passed;
            var report=new Report
            {
                platform=Application.platform.ToString(),unity=Application.unityVersion,device=SystemInfo.deviceModel,
                graphics=SystemInfo.graphicsDeviceName,timestampUtc=DateTime.UtcNow.ToString("O"),passed=passed,
                runtimeErrors=errors,replayIterations=replays,checks=checks.ToArray(),frameSamples=frameTimes.Count,
                sampleWallSeconds=sampleWallSeconds,frameMedianMs=Percentile(.5f),frameP95Ms=Percentile(.95f)
            };
            try
            {
                Directory.CreateDirectory(outputDirectory);
                string path=Path.Combine(outputDirectory,"runtime_checks.json");
                File.WriteAllText(path,JsonUtility.ToJson(report,true));
                Debug.Log("WOOL_RUNTIME_CHECKS "+(passed?"PASS ":"FAIL ")+path);
            }
            catch(Exception exception){Debug.LogException(exception);passed=false;}
            if(quit)Application.Quit(passed?0:1);
        }
        float Percentile(float fraction)
        {return frameTimes.Count==0?0:frameTimes[Mathf.Clamp(Mathf.CeilToInt(frameTimes.Count*fraction)-1,0,frameTimes.Count-1)];}
    }
}
