using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using CozyRescue.Demo;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.LowLevel;
using UnityEngine.UI;

namespace CozyRescue.Presentation
{
    /// <summary>Opt-in synthetic Input System events through real ReadPointer/raycast and UI routing.</summary>
    public sealed class WoolPointerChecks : MonoBehaviour
    {
        [Serializable] public sealed class Check { public string name; public bool passed; public string detail; }
        [Serializable] public sealed class Report
        {
            public string scope="Actual Unity player, synthetic MouseState events through Input System, WoolLab.ReadPointer, Physics.Raycast and uGUI. NOT native desktop clicking, physical mouse input, Android touch or usability validation.";
            public string platform,unity,timestampUtc;
            public bool passed;
            public int runtimeErrors;
            public Check[] checks;
        }
        readonly List<Check> checks=new List<Check>();
        readonly List<InputDevice> disabledDevices=new List<InputDevice>();
        Mouse mouse;
        InputSettings.BackgroundBehavior originalBackground;
        bool configured,quit;
        int errors,departures,rejections,lastRejected=-1;
        string outputDirectory;
        WoolLab lab;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Install()
        {
            if(Array.IndexOf(Environment.GetCommandLineArgs(),"--wool-pointer-checks")<0)return;
            new GameObject("Opt-in synthetic pointer checks").AddComponent<WoolPointerChecks>();
        }
        void OnEnable(){Application.logMessageReceived+=OnLog;}
        void OnLog(string condition,string trace,LogType type)
        {if(type==LogType.Error||type==LogType.Exception||type==LogType.Assert)errors++;}
        void OnDestroy()
        {
            Application.logMessageReceived-=OnLog;
            if(lab!=null&&lab.Session!=null)lab.Session.Changed-=OnDemoEvent;
            if(mouse!=null&&mouse.added)InputSystem.RemoveDevice(mouse);
            foreach(var device in disabledDevices)if(device.added)InputSystem.EnableDevice(device);
            if(configured)InputSystem.settings.backgroundBehavior=originalBackground;
        }
        void OnDemoEvent(DemoEvent e)
        {if(e.Kind==DemoEventKind.Departure)departures++;if(e.Kind==DemoEventKind.Rejected){rejections++;lastRejected=e.BlockId;}}
        void Record(string name,bool passed,string detail="")
        {checks.Add(new Check{name=name,passed=passed,detail=detail});}
        IEnumerator Start()
        {
            string[] args=Environment.GetCommandLineArgs();outputDirectory=Application.persistentDataPath;
            quit=Array.IndexOf(args,"--wool-quit")>=0;
            for(int i=0;i<args.Length-1;i++)if(args[i]=="--wool-checks-dir"||args[i]=="--wool-pointer-checks-dir")outputDirectory=args[i+1];
            yield return null;
            if(Array.IndexOf(args,"--wool-demo")>=0||Array.IndexOf(args,"--wool-capture")>=0||Array.IndexOf(args,"--wool-checks")>=0)
            {Record("Exclusive pointer-check mode",false,"Run separately from automatic demo, capture, and API checks.");Finish();yield break;}
            lab=FindFirstObjectByType<WoolLab>();
            if(lab==null||lab.Session==null){Record("Initialized WoolLab",false);Finish();yield break;}
            lab.automaticDemo=false;lab.playbackSpeed=1;lab.Replay();lab.Session.Changed+=OnDemoEvent;
            originalBackground=InputSystem.settings.backgroundBehavior;configured=true;
            InputSystem.settings.backgroundBehavior=InputSettings.BackgroundBehavior.IgnoreFocus;
            // Isolate only this explicit CLI run from other pointer devices; restore at teardown.
            foreach(var device in InputSystem.devices)
                if((device is Mouse||device is Touchscreen)&&device.enabled){disabledDevices.Add(device);InputSystem.DisableDevice(device);}
            mouse=InputSystem.AddDevice<Mouse>("WoolSyntheticMouse");mouse.MakeCurrent();
            yield return Send(new Vector2(5,5),false);
            Vector2 blocked,valid;
            bool foundB=BlockPoint(1,out blocked),foundD=BlockPoint(3,out valid);
            Record("Projected block targets",foundB&&foundD);
            if(!foundB||!foundD){Finish();yield break;}

            int beforeReject=rejections;
            yield return Click(blocked);
            Record("Blocked B reaches raycast then rejects",rejections==beforeReject+1&&lastRejected==1&&lab.Session.Blocks[1].Phase==BlockPhase.Board);

            int beforeDepart=departures;
            float dpi=Screen.dpi>0?Screen.dpi:160;
            yield return Send(valid,true);
            yield return Send(valid+Vector2.right*(24*dpi/160),true);
            yield return Send(valid,true);
            yield return Send(valid,false);
            Record("Drag beyond 8 dp then return cancels tap",departures==beforeDepart&&lab.Session.Blocks[3].Phase==BlockPhase.Board,"Synthetic held pointer excursion 24 dp.");

            yield return Send(valid,true);
            float held=Time.unscaledTime;
            while(Time.unscaledTime-held<.42f)yield return null;
            yield return Send(valid,false);
            Record("Hold beyond 350 ms cancels tap",departures==beforeDepart&&lab.Session.Blocks[3].Phase==BlockPhase.Board,"Held at least 420 ms wall time.");

            yield return Click(valid);
            Record("Short D tap departs via ReadPointer",departures==beforeDepart+1&&lab.Session.Blocks[3].Phase!=BlockPhase.Board,"No Session.TrySelect or WoolLab.Select invocation in this check runner.");

            Vector2 button;
            if(ButtonPoint("잠깐",out button))
            {
                yield return Click(button);float pausedTime=lab.Session.Time;int pausedCount=lab.Session.ConsumedCount;
                float begin=Time.unscaledTime;while(Time.unscaledTime-begin<.25f)yield return null;
                Record("uGUI pause click freezes clock",lab.Session.Paused&&lab.Session.Time==pausedTime&&lab.Session.ConsumedCount==pausedCount);
            }
            else Record("uGUI pause button found",false);
            if(ButtonPoint("계속하기",out button))
            {
                float pausedTime=lab.Session.Time;yield return Click(button);yield return null;
                Record("uGUI resume click resumes clock",!lab.Session.Paused&&lab.Session.Time>pausedTime);
            }
            else Record("uGUI resume button found",false);
            if(ButtonPoint("다시 보기",out button))
            {
                int revision=lab.Session.Revision;yield return Click(button);
                bool reset=lab.Session.Revision==revision+1&&lab.Session.ConsumedCount==0&&!lab.Session.Won;
                foreach(var block in lab.Session.Blocks)reset=reset&&block.Phase==BlockPhase.Board;
                Record("uGUI replay click restores board",reset);
            }
            else Record("uGUI replay button found",false);
            if(ButtonPoint("0.5×",out button))
            {
                yield return Click(button);
                Record("Speed button selects half speed",lab.playbackSpeed==.5f);
                if(ButtonPoint("1×",out button)){yield return Click(button);Record("Speed button restores normal speed",lab.playbackSpeed==1);}
                else Record("Normal-speed button found",false);
            }
            else Record("Half-speed button found",false);
            Record("No runtime errors",errors==0);
            Finish();
        }
        IEnumerator Send(Vector2 position,bool pressed)
        {
            mouse.MakeCurrent();
            InputSystem.QueueStateEvent(mouse,new MouseState{position=position}.WithButton(MouseButton.Left,pressed));
            // Let the ordinary Input System player-loop update process events before gameplay/UI.
            yield return null;
            yield return null;
        }
        IEnumerator Click(Vector2 point){yield return Send(point,false);yield return Send(point,true);yield return Send(point,false);}
        bool BlockPoint(int id,out Vector2 point)
        {
            foreach(var tag in lab.GetComponentsInChildren<WoolBlockTag>())
                if(tag.id==id){var collider=tag.GetComponent<Collider>();point=Camera.main.WorldToScreenPoint(collider.bounds.center);return true;}
            point=default;return false;
        }
        bool ButtonPoint(string title,out Vector2 point)
        {
            foreach(var button in lab.GetComponentsInChildren<Button>())
            {
                var text=button.GetComponentInChildren<Text>();
                if(text!=null&&text.text==title&&button.IsActive()&&button.interactable)
                {var rect=(RectTransform)button.transform;point=RectTransformUtility.WorldToScreenPoint(null,rect.TransformPoint(rect.rect.center));return true;}
            }
            point=default;return false;
        }
        void Finish()
        {
            bool passed=errors==0;foreach(var check in checks)passed=passed&&check.passed;
            var report=new Report{platform=Application.platform.ToString(),unity=Application.unityVersion,timestampUtc=DateTime.UtcNow.ToString("O"),passed=passed,runtimeErrors=errors,checks=checks.ToArray()};
            try{Directory.CreateDirectory(outputDirectory);string path=Path.Combine(outputDirectory,"pointer_checks.json");File.WriteAllText(path,JsonUtility.ToJson(report,true));Debug.Log("WOOL_POINTER_CHECKS "+(passed?"PASS ":"FAIL ")+path);}
            catch(Exception exception){Debug.LogException(exception);passed=false;}
            if(quit)Application.Quit(passed?0:1);
        }
    }
}
