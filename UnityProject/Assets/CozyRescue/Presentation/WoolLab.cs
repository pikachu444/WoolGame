using System;
using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using CozyRescue.Demo;

namespace CozyRescue.Presentation
{
    public sealed partial class WoolLab : MonoBehaviour
    {
        public WoolLabSettings settings;
        public bool automaticDemo;
        public bool evidenceCapture;
        public string evidenceDirectory;
        public float playbackSpeed=1;
        public DemoSession Session {get;private set;}
        Camera cam;Transform stage;Canvas canvas;RectTransform safeUI;
        Font font;Material[] yarn;Material cream,wood,ink,ground;Mesh box,cuff;
        Transform dragon,cat,wavingPaw,eyeLeft,eyeRight;Vector3 dragonScale,catHome,eyeLeftScale,eyeRightScale;Quaternion pawRest;WoolPath path;
        readonly Transform[] units=new Transform[24],blocks=new Transform[4],spools=new Transform[4];
        readonly Vector3[] blockStart=new Vector3[4],slotPosition=new Vector3[4],captureSource=new Vector3[24];
        readonly float[] capturedAt=new float[24],feedbackAt=new float[4],lastAmount=new float[4];
        readonly bool[] seenCapture=new bool[24];
        readonly WoolTube[] threads=new WoolTube[4],coils=new WoolTube[4];
        readonly WoolTube[] woundBodies=new WoolTube[4],sourceLoops=new WoolTube[4];
        readonly WoolPath[] returnPaths=new WoolPath[4];
        readonly Text[] blockLabels=new Text[4],slotLabels=new Text[4];
        readonly Text[] rescueHearts=new Text[5];
        Text progress,status,pauseLabel,speedLabel;GameObject pausePanel,successPanel;Text soundLabel,hapticLabel;
        MaterialPropertyBlock propertyBlock;float successAt=-1;int screenWidth,screenHeight;Rect safeRect;
        float pressAt;Vector2 pressPosition;int pressBlock=-1;float inputFeedbackClock;bool muted=true,haptic=false;
        AudioSource audioSource;AudioClip pluck;float autoTime;int autoStep;int lastRevision=-1;
        static readonly int BaseColor=Shader.PropertyToID("_BaseColor"),Unravel=Shader.PropertyToID("_Unravel");
        readonly string[] directions={"↑","→","↓","←"};
        readonly int[] scriptedOrder={3,2,1,0};
        readonly string[] progressText=new string[25],counterText=new string[11];
        int displayedProgress=-1;float rejectedUntil=-1;
        readonly System.Collections.Generic.List<UnityEngine.Object> ownedPresentationAssets=new System.Collections.Generic.List<UnityEngine.Object>();
        T Own<T>(T asset) where T:UnityEngine.Object {ownedPresentationAssets.Add(asset);return asset;}
        WoolTube OwnTube(WoolTube tube){Own(tube.GameObject.GetComponent<MeshFilter>().sharedMesh);return tube;}
        void ReleasePresentationAssets()
        {
            if(audioSource)audioSource.Stop();
            foreach(var asset in ownedPresentationAssets)if(asset){if(Application.isPlaying)Destroy(asset);else DestroyImmediate(asset);}
            ownedPresentationAssets.Clear();pluck=null;
        }
        void OnDestroy(){ReleasePresentationAssets();}
        public void Awake()
        {
            if(!Application.isPlaying)return;
            if(settings==null)settings=ScriptableObject.CreateInstance<WoolLabSettings>();
            foreach(string arg in Environment.GetCommandLineArgs()) {if(arg=="--wool-demo")automaticDemo=true;if(arg=="--wool-capture")evidenceCapture=true;}
            Session=new DemoSession();propertyBlock=new MaterialPropertyBlock();Application.runInBackground=true;
            for(int i=0;i<25;i++)progressText[i]=i+" / 24";for(int i=0;i<11;i++)counterText[i]=i.ToString();Application.targetFrameRate=60;
            BuildPresentation();ResetVisualState();
            if(evidenceCapture){automaticDemo=true;var capture=gameObject.AddComponent<WoolEvidenceCapture>();capture.outputDirectory=evidenceDirectory;}
        }
        public void BuildPresentation()
        {
            var existing=stage?stage:transform.Find("Presentation");if(existing!=null){existing.gameObject.SetActive(false);if(Application.isPlaying)Destroy(existing.gameObject);else DestroyImmediate(existing.gameObject);}
            ReleasePresentationAssets();
            stage=new GameObject("Presentation").transform;stage.SetParent(transform,false);
            cam=Camera.main;
            if(cam==null){var cg=new GameObject("WoolLab Fixed Camera");cg.tag="MainCamera";cam=cg.AddComponent<Camera>();cg.AddComponent<AudioListener>();}
            cam.orthographic=true;cam.orthographicSize=5.4f/((float)Mathf.Max(1,Screen.width)/Mathf.Max(1,Screen.height));cam.transform.position=new Vector3(0,24,-8.735f);cam.transform.rotation=Quaternion.LookRotation(-cam.transform.position,Vector3.forward);cam.backgroundColor=settings.background;cam.clearFlags=CameraClearFlags.SolidColor;cam.nearClipPlane=.1f;cam.farClipPlane=80;
            RenderSettings.ambientMode=UnityEngine.Rendering.AmbientMode.Trilight;RenderSettings.ambientSkyColor=new Color(.79f,.81f,.89f);RenderSettings.ambientEquatorColor=new Color(.64f,.64f,.69f);RenderSettings.ambientGroundColor=new Color(.5f,.46f,.46f);
            var lightGo=new GameObject("Soft window light");lightGo.transform.SetParent(stage);lightGo.transform.rotation=Quaternion.Euler(68,-32,0);var l=lightGo.AddComponent<Light>();l.type=LightType.Directional;l.intensity=1.0f;l.color=new Color(1,.98f,.96f);l.shadows=LightShadows.Soft;l.shadowStrength=.48f;l.shadowBias=.015f;l.shadowNormalBias=.03f;
            yarn=new Material[4];for(int i=0;i<4;i++)yarn[i]=MakeYarn(settings.yarnColors[i]);
            cream=MakeYarn(WoolLabSettings.Hex("EEE4D1"));wood=Lit(WoolLabSettings.Hex("CDAF91"),.35f);ink=Lit(settings.ink,.18f);ground=Lit(WoolLabSettings.Hex("A6BED0"),.04f);
            box=Own(WoolGeometry.RoundedBox(Vector3.one,.16f));cuff=settings.cuffMesh!=null?settings.cuffMesh:Own(WoolGeometry.Cuff());
            WoolGeometry.MeshObject("Soft linen backdrop",stage,box,ground,new Vector3(0,-.65f,0),new Vector3(40,.6f,50));
            BuildUI();Canvas.ForceUpdateCanvases();BuildStage();BuildAudio();Layout();
        }
        Material Lit(Color color,float smooth)
        {
            var m=Own(new Material(settings.surfaceShader?settings.surfaceShader:Shader.Find("Universal Render Pipeline/Lit")));m.SetColor("_BaseColor",color);m.SetFloat("_Smoothness",smooth);return m;
        }
        Material Linen(Color color,float repeats)
        {
            var material=Lit(color,.08f);const int size=32;
            var texture=Own(new Texture2D(size,size,TextureFormat.RGBA32,true,true));texture.name="Original linen weave";texture.wrapMode=TextureWrapMode.Repeat;
            var pixels=new Color[size*size];
            for(int y=0;y<size;y++)for(int x=0;x<size;x++){
                float warp=.5f+.5f*Mathf.Cos(x*Mathf.PI*.5f),weft=.5f+.5f*Mathf.Cos(y*Mathf.PI*.5f);
                float weave=((x/4+y/4)%2==0?warp:weft);float fiber=((x*17+y*31)%19)/18f;
                float value=.945f+.035f*weave+.02f*fiber;pixels[y*size+x]=new Color(value,value,value,1);
            }
            texture.SetPixels(pixels);texture.Apply(true,true);material.SetTexture("_BaseMap",texture);material.SetTextureScale("_BaseMap",Vector2.one*repeats);return material;
        }
        Material MakeYarn(Color color)
        {
            var m=Own(new Material(settings.knitShader?settings.knitShader:Shader.Find("CozyRescue/KnitLit")));m.SetColor("_BaseColor",color);m.SetFloat("_Stitches",settings.stitchColumns);m.SetFloat("_BumpScale",settings.normalStrength*1.65f);m.SetFloat("_Smoothness",settings.smoothness);m.SetFloat("_Fuzz",settings.fuzz);
            m.SetFloat("_AOFloor",settings.physicalKnit?0:.72f);if(settings.physicalKnit)m.SetFloat("_BumpScale",.85f);
            if(settings.knitNormal&&settings.knitAO){m.SetTexture("_BumpMap",settings.knitNormal);m.SetTexture("_OcclusionMap",settings.knitAO);m.SetFloat("_HasTextures",1);}return m;
        }
        Transform MakeActor(GameObject prefab,bool isDragon)
        {
            if(prefab){var actor=Instantiate(prefab,stage);actor.name=isDragon?"Som Cloud Dragon":"Cream Cat";
                var palette=new System.Collections.Generic.Dictionary<string,Material>();
                foreach(var r in actor.GetComponentsInChildren<Renderer>()){var mats=r.sharedMaterials;for(int j=0;j<mats.Length;j++){
                    string name=mats[j]?mats[j].name.ToLowerInvariant():"";
                    if(!palette.TryGetValue(name,out var material)){
                        if(name.Contains("highlight")||name.Contains("white"))material=Lit(Color.white,.3f);
                        else if(name.Contains("eye")||name.Contains("pupil")||name.Contains("mouth"))material=Lit(WoolLabSettings.Hex("493225"),.35f);
                        else if(name.Contains("nose")||name.Contains("blush"))material=MakeYarn(WoolLabSettings.Hex("EAB5AD"));
                        else if(name.Contains("patch")||name.Contains("cocoa"))material=MakeYarn(WoolLabSettings.Hex("A98E85"));
                        else if(name.Contains("scarf"))material=MakeYarn(WoolLabSettings.Hex("E65B47"));
                        else if(isDragon&&name.Contains("wool"))material=MakeYarn(WoolLabSettings.Hex("EF982B"));
                        else if(name.Contains("cream"))material=MakeYarn(WoolLabSettings.Hex(isDragon?"FFE7A2":"FFF0CA"));
                        else if(name.Contains("wool"))material=MakeYarn(WoolLabSettings.Hex("E8B65F"));
                        else material=cream;
                        palette.Add(name,material);
                    }
                    mats[j]=material;
                }r.sharedMaterials=mats;}return actor.transform;}
            var root=new GameObject(isDragon?"Authored cloud dragon":"Authored cream cat").transform;root.SetParent(stage,false);
            Sphere(root,"Stuffed head",new Vector3(0,.42f,0),new Vector3(1.2f,.76f,.90f),cream);
            Sphere(root,"Muzzle",new Vector3(0,.31f,.40f),new Vector3(.76f,.40f,.37f),cream);
            for(int side=-1;side<=1;side+=2){Sphere(root,"Soft ear",new Vector3(side*.47f,.78f,-.02f),new Vector3(.32f,.48f,.22f),cream);Sphere(root,"Eye",new Vector3(side*.27f,.53f,.382f),new Vector3(.19f,.235f,.08f),ink);Sphere(root,"Eye glint",new Vector3(side*.27f-.025f,.565f,.423f),Vector3.one*.053f,Lit(Color.white,.1f));}
            if(!isDragon){Sphere(root,"Short body",new Vector3(0,-.06f,-.03f),new Vector3(.70f,.65f,.50f),cream);for(int s=-1;s<=1;s+=2)Sphere(root,"Paw",new Vector3(s*.24f,-.28f,.19f),new Vector3(.29f,.25f,.39f),cream);}return root;
        }
        void Sphere(Transform parent,string name,Vector3 pos,Vector3 scale,Material material){var g=GameObject.CreatePrimitive(PrimitiveType.Sphere);g.name=name;g.transform.SetParent(parent,false);g.transform.localPosition=pos;g.transform.localScale=scale;g.GetComponent<Renderer>().sharedMaterial=material;Destroy(g.GetComponent<Collider>());}
        Vector3 Grid(float x,float y)=>World(.315f+x*.185f,.235f+y*.086f);
        Vector3 World(float x,float y)
        {
            Rect r=Application.isPlaying?Screen.safeArea:new Rect(0,0,Screen.width,Screen.height);
            var ray=cam.ScreenPointToRay(new Vector3(r.x+x*r.width,r.y+y*r.height,0));new Plane(Vector3.up,Vector3.zero).Raycast(ray,out float d);return ray.GetPoint(d);
        }
        void Layout()
        {
            screenWidth=Screen.width;screenHeight=Screen.height;safeRect=Screen.safeArea;
            if(safeUI){safeUI.anchorMin=new Vector2(safeRect.x/screenWidth,safeRect.y/screenHeight);safeUI.anchorMax=new Vector2(safeRect.xMax/screenWidth,safeRect.yMax/screenHeight);safeUI.offsetMin=safeUI.offsetMax=Vector2.zero;}
            for(int s=0;s<4;s++){slotPosition[s]=World(.20f+s*.2f,.598f);slotPosition[s].y=.22f;}
        }
        void ResetVisualState()
        {
            lastRevision=Session.Revision;successAt=-1;autoTime=0;autoStep=0;pressBlock=-1;displayedProgress=-1;rejectedUntil=-1;
            for(int i=0;i<24;i++){seenCapture[i]=false;capturedAt[i]=-10;units[i].gameObject.SetActive(true);units[i].localScale=Vector3.one*settings.bodyWidth;SetUnitMaterial(i,0);
                var unit=Session.Units[i];float poseTime=unit.Consumed?unit.CaptureTime:Session.Time;int ahead=0;
                for(int j=0;j<i;j++)if(!Session.Units[j].Consumed||Session.Units[j].CaptureTime>=poseTime)ahead++;
                float s=path.Length-1.25f+Mathf.Sin(poseTime*.35f)*settings.pathSpeed-(ahead+1)*settings.bodyPitch*settings.bodyWidth;
                units[i].position=path.At(s)+Vector3.up*(.13f+.022f*Mathf.Sin(poseTime*2.2f+i*.40f));units[i].rotation=path.Rotation(s);
            }
            for(int i=0;i<4;i++){feedbackAt[i]=-10;lastAmount[i]=0;returnPaths[i]=null;blockLabels[i].transform.localScale=Vector3.one;blocks[i].position=blockStart[i];blocks[i].localScale=Vector3.one;blocks[i].gameObject.SetActive(true);spools[i].gameObject.SetActive(false);threads[i].GameObject.SetActive(false);coils[i].GameObject.SetActive(false);woundBodies[i].GameObject.SetActive(false);sourceLoops[i].GameObject.SetActive(false);blockLabels[i].gameObject.SetActive(true);blockLabels[i].text="<size=21><b>"+Session.Blocks[i].Capacity+"</b></size>";slotLabels[i].text="·";}
            pausePanel.SetActive(false);successPanel.SetActive(false);cat.position=catHome;cat.localScale=Vector3.one*1.20f;dragon.localScale=dragonScale;dragon.gameObject.SetActive(true);UpdatePresentation(0);
        }
        public void Replay(){Session.Reset();ResetVisualState();}
        public void Step(){if(!Session.Paused)TogglePause();Session.Paused=false;Session.Advance(1f/30);Session.Paused=true;UpdatePresentation(1f/30);}
        public void TogglePause(){Session.Paused=!Session.Paused;pausePanel.SetActive(Session.Paused);pauseLabel.text=Session.Paused?"계속":"잠깐";}
        void OnApplicationPause(bool paused){if(paused&&Session!=null){Session.Paused=true;if(pausePanel)pausePanel.SetActive(true);}}
        void Update()
        {
            if(Session==null)return;
            if(screenWidth!=Screen.width||screenHeight!=Screen.height||safeRect!=Screen.safeArea)
            {
                float savedAuto=autoTime;int savedStep=autoStep;bool paused=Session.Paused;
                BuildPresentation();ResetVisualState();autoTime=savedAuto;autoStep=savedStep;pausePanel.SetActive(paused);pauseLabel.text=paused?"계속":"잠깐";soundLabel.text=muted?"소리 꺼짐":"소리 켜짐";hapticLabel.text=haptic?"진동 켜짐":"진동 꺼짐";speedLabel.text=playbackSpeed==1?"0.5×":"1×";
            }
            if(!Session.Paused)inputFeedbackClock+=Time.unscaledDeltaTime;
            if(Keyboard.current!=null&&Keyboard.current.escapeKey.wasPressedThisFrame)TogglePause();
            ReadPointer();
            float dt=Time.deltaTime*playbackSpeed;
            if(automaticDemo&&!Session.Paused){autoTime+=dt;if(autoStep<4&&autoTime>=2+autoStep*.65f){Select(scriptedOrder[autoStep]);autoStep++;}}
            Session.Advance(dt);if(Session.Revision!=lastRevision)ResetVisualState();UpdatePresentation(Session.Paused?0:dt);
        }
        void ReadPointer()
        {
            if(Session.Paused||Session.Won){pressBlock=-1;return;}
            bool down=false,up=false;Vector2 pos=default;
            if(Touchscreen.current!=null&&Touchscreen.current.primaryTouch.press.isPressed){pos=Touchscreen.current.primaryTouch.position.ReadValue();down=Touchscreen.current.primaryTouch.press.wasPressedThisFrame;}
            if(Touchscreen.current!=null&&Touchscreen.current.primaryTouch.press.wasReleasedThisFrame){pos=Touchscreen.current.primaryTouch.position.ReadValue();up=true;}
            if(Mouse.current!=null){if(Mouse.current.leftButton.wasPressedThisFrame){pos=Mouse.current.position.ReadValue();down=true;}if(Mouse.current.leftButton.wasReleasedThisFrame){pos=Mouse.current.position.ReadValue();up=true;}}
            if(down){pressBlock=-1;pressAt=Time.unscaledTime;pressPosition=pos;var ray=cam.ScreenPointToRay(pos);if(Physics.Raycast(ray,out var hit,100)&&hit.collider.TryGetComponent<WoolBlockTag>(out var tag)){pressBlock=tag.id;feedbackAt[tag.id]=inputFeedbackClock;}}
            if(pressBlock>=0&&!up){Vector2 current=Touchscreen.current!=null&&Touchscreen.current.primaryTouch.press.isPressed?Touchscreen.current.primaryTouch.position.ReadValue():Mouse.current!=null?Mouse.current.position.ReadValue():pressPosition;float dpi=Screen.dpi>0?Screen.dpi:160;if((current-pressPosition).magnitude>8*dpi/160)pressBlock=-1;}
            if(up&&pressBlock>=0){float dpi=Screen.dpi>0?Screen.dpi:160;bool tap=(pos-pressPosition).magnitude<=8*dpi/160&&Time.unscaledTime-pressAt<=.35f;int id=pressBlock;pressBlock=-1;if(tap)Select(id);}
        }
        public bool Select(int id)
        {
            if(id<0||id>=4)return false;
            feedbackAt[id]=inputFeedbackClock;bool accepted=Session.TrySelect(id);
            if(accepted){if(!muted)audioSource.PlayOneShot(pluck,.22f);
#if UNITY_ANDROID && !UNITY_EDITOR
                if(haptic)Handheld.Vibrate();
#endif
            }else {status.text="화살표 앞의 블록부터 꺼내 주세요";rejectedUntil=inputFeedbackClock+1.4f;}
            return accepted;
        }
        void UpdatePresentation(float dt)
        {
            float time=Session.Time;float headDistance=path.Length-1.25f+Mathf.Sin(time*.35f)*settings.pathSpeed;
            if(eyeLeft)eyeLeft.localScale=eyeLeftScale;if(eyeRight)eyeRight.localScale=eyeRightScale;
            foreach(var heart in rescueHearts)if(heart)heart.gameObject.SetActive(false);if(wavingPaw)wavingPaw.localRotation=pawRest;
            int remainingIndex=0;float latestCapture=-10,closingGap=0;
            for(int i=0;i<24;i++)
            {
                var unit=Session.Units[i];
                if(unit.Consumed&&!seenCapture[i]){seenCapture[i]=true;capturedAt[i]=unit.CaptureTime;captureSource[i]=units[i].position;}
                if(unit.Consumed){latestCapture=Mathf.Max(latestCapture,capturedAt[i]);float p=Mathf.Clamp01((time-capturedAt[i])/.45f);
                    closingGap+=1-Mathf.SmoothStep(0,1,Mathf.InverseLerp(.18f,.45f,time-capturedAt[i]));
                    if(p>=1){units[i].gameObject.SetActive(false);continue;}
                    Vector3 pull=slotPosition[unit.CapturedBySlot];Vector3 source=captureSource[i];units[i].position=Vector3.Lerp(source,source+(pull-source).normalized*.28f,p*p);
                    units[i].localScale=settings.bodyWidth*new Vector3(Mathf.Lerp(1,.78f,p*p),Mathf.Lerp(1,.65f,p),1);SetUnitMaterial(i,p);
                }
                else {float s=headDistance-(remainingIndex+closingGap+1)*settings.bodyPitch*settings.bodyWidth;Vector3 target=path.At(s)+Vector3.up*(.13f+.022f*Mathf.Sin(time*2.2f+i*.40f));
                    if(time<.02f)units[i].position=target;else units[i].position=Vector3.Lerp(units[i].position,target,1-Mathf.Exp(-dt*24));units[i].rotation=Quaternion.Slerp(units[i].rotation,path.Rotation(s),time<.02f?1:1-Mathf.Exp(-dt*20));remainingIndex++;}
            }
            dragon.position=path.At(headDistance)+Vector3.up*.35f;dragon.rotation=Quaternion.Slerp(path.Rotation(headDistance),Quaternion.Euler(0,165,0),.72f)*Quaternion.Euler(25,0,0);dragon.localScale=dragonScale*(1+.014f*Mathf.Sin(time*2));
            for(int b=0;b<4;b++)UpdateBlockAndSpool(b,time);
            if(displayedProgress!=Session.ConsumedCount){displayedProgress=Session.ConsumedCount;progress.text=progressText[displayedProgress];}
            if(!Session.Won&&pressBlock<0&&inputFeedbackClock>rejectedUntil)status.text=Session.ConsumedCount==0?"화살표를 따라, 한 올씩 풀어 주세요":"포근한 실이 모이고 있어요";
            if(Session.Won&&time>=latestCapture+.50f)
            {
                if(successAt<0){successAt=time;successPanel.SetActive(true);if(!muted)audioSource.PlayOneShot(pluck,.35f);}
                float p=Mathf.Clamp01((time-successAt)/1.2f);cat.position=catHome+(Vector3.up*.65f+Vector3.forward*.18f)*Mathf.Sin(p*Mathf.PI);cat.localScale=Vector3.one*1.20f+new Vector3(-.08f,.14f,-.08f)*Mathf.Sin(p*Mathf.PI*4)*(1-p);
                if(wavingPaw)wavingPaw.localRotation=pawRest*Quaternion.Euler(0,Mathf.Sin(p*Mathf.PI*5)*30,0);
                float smile=Mathf.Sin(Mathf.Clamp01(p*2)*Mathf.PI*.5f);if(eyeLeft)eyeLeft.localScale=Vector3.Scale(eyeLeftScale,new Vector3(1,1,1-.80f*smile));if(eyeRight)eyeRight.localScale=Vector3.Scale(eyeRightScale,new Vector3(1,1,1-.80f*smile));
                for(int h=0;h<rescueHearts.Length;h++){var heart=rescueHearts[h];heart.gameObject.SetActive(p<1);heart.rectTransform.anchoredPosition=new Vector2((h-2)*(20+35*p),35+70*p-Mathf.Abs(h-2)*12);heart.color=new Color(.80f,.20f,.30f,1-p);}
                dragon.position+=new Vector3(Mathf.SmoothStep(0,1,p)*2,Mathf.Sin(p*Mathf.PI)*.3f,0);dragon.localScale=dragonScale*Mathf.Lerp(1,.78f,p);status.text="오늘도 한 친구를 구했어요";
            }
        }
        Transform FindPart(Transform root,string text){foreach(Transform t in root){if(t.name.ToLowerInvariant().Contains(text))return t;var child=FindPart(t,text);if(child)return child;}return null;}
        void SetUnitMaterial(int i,float p){var r=units[i].GetComponent<Renderer>();r.GetPropertyBlock(propertyBlock);propertyBlock.SetFloat(Unravel,p);r.SetPropertyBlock(propertyBlock);}
        void UpdateBlockAndSpool(int b,float time)
        {
            var block=Session.Blocks[b];bool board=block.Phase==BlockPhase.Board,travel=block.Phase==BlockPhase.InTransit;
            blocks[b].gameObject.SetActive(board||travel);blockLabels[b].gameObject.SetActive(board||travel);
            if(board){float f=Mathf.Clamp01((inputFeedbackClock-feedbackAt[b])/.13f);blocks[b].localScale=new Vector3(1+.035f*(1-f),1-.14f*(1-f),1+.035f*(1-f));}
            if(travel){float p=Mathf.Clamp01((time-block.DepartTime)/.38f);Vector3 start=blockStart[b];Vector3 escape=start;
                if(b==0)escape.z=World(.5f,.548f).z;else if(b==1)escape.x=World(.95f,.5f).x;else if(b==2)escape.z=World(.5f,.105f).z;else escape.x=World(.045f,.5f).x;escape.y=.22f;
                Vector3 dest=slotPosition[block.Slot];
                if(returnPaths[b]==null){float side=b==3?.045f:.95f;Vector3 edge=World(side,b==2?.105f:.548f),top=World(side,.548f),approach=World(.20f+block.Slot*.20f,.548f);edge.y=top.y=approach.y=.22f;
                    returnPaths[b]=b==0?new WoolPath(new[]{escape,approach,dest}):new WoolPath(new[]{escape,edge,top,approach,dest});}
                if(p<.42f)blocks[b].position=Vector3.Lerp(start,escape,p/.42f);else{float q=(p-.42f)/.58f;blocks[b].position=returnPaths[b].At(returnPaths[b].Length*Mathf.SmoothStep(0,1,q));}
                float shrink=Mathf.Lerp(1,.40f,Mathf.SmoothStep(0,1,Mathf.InverseLerp(.25f,.65f,p)));blocks[b].localScale=Vector3.one*shrink;blockLabels[b].transform.localScale=Vector3.one*shrink;
            }
            if(board||travel)PlaceText(blockLabels[b],blocks[b].position+Vector3.up*.27f);
            if(block.Slot<0)return;
            bool working=block.Phase==BlockPhase.Working,finished=block.Phase==BlockPhase.Finished;float visualAmount=0,latest=-1;int activeUnit=-1;
            for(int i=0;i<24;i++)if(Session.Units[i].ColorId==b&&seenCapture[i]){float p=Mathf.Clamp01((time-capturedAt[i])/.45f);visualAmount+=p;if(capturedAt[i]>latest){latest=capturedAt[i];if(p<1||working)activeUnit=i;}}
            float completion=finished?Mathf.Clamp01((time-latest-.45f)/.2f):0;
            bool replaced=false;for(int other=0;other<4;other++)if(other!=b&&Session.Blocks[other].Slot==block.Slot&&Session.Blocks[other].Phase==BlockPhase.Working)replaced=true;
            bool visible=(working||finished)&&completion<1&&!(finished&&replaced);spools[b].gameObject.SetActive(visible);coils[b].GameObject.SetActive(visible&&visualAmount>.01f);woundBodies[b].GameObject.SetActive(visible&&visualAmount>.01f);
            spools[b].position=slotPosition[block.Slot];spools[b].localScale=Vector3.one*(1+.10f*Mathf.Sin(Mathf.Clamp01((time-block.ArrivalTime)/.12f)*Mathf.PI))*(1-completion*.95f);
            float fraction=visualAmount/block.Capacity;float turns=9+5*fraction;Vector3 end=slotPosition[block.Slot];
            float coreRadius=.14f+.16f*Mathf.Sqrt(fraction);for(int j=0;j<3;j++)woundBodies[b].Points[j]=slotPosition[block.Slot]+Vector3.right*Mathf.Lerp(-.47f,.47f,j*.5f);if(visible&&visualAmount>.01f)woundBodies[b].Update(coreRadius*(1-completion));
            for(int j=0;j<coils[b].Points.Length;j++){float q=(float)j/(coils[b].Points.Length-1);float a=q*turns*Mathf.PI*2;float x=Mathf.Lerp(-.47f,.47f,q);end=slotPosition[block.Slot]+new Vector3(x,Mathf.Cos(a)*(coreRadius+.035f),Mathf.Sin(a)*(coreRadius+.035f));coils[b].Points[j]=end;}if(visible&&visualAmount>.01f)coils[b].Update(.067f*(1-completion));
            threads[b].GameObject.SetActive(visible&&activeUnit>=0);
            sourceLoops[b].GameObject.SetActive(visible&&activeUnit>=0);
            if(visible&&activeUnit>=0){float peel=Mathf.Clamp01((time-capturedAt[activeUnit])/.45f);float edgeZ=.41f-.78f*peel;
                Vector3 source=units[activeUnit].TransformPoint(new Vector3(0,Mathf.Max(.09f,.025f+.205f*Mathf.Sqrt(Mathf.Max(0,1-Mathf.Pow((edgeZ-.185f)/.22f,2)))),edgeZ));
                float loopRadius=.10f*(1-.65f*peel);for(int j=0;j<15;j++){float a=j/14f*Mathf.PI*1.5f;sourceLoops[b].Points[j]=source+units[activeUnit].right*Mathf.Cos(a)*loopRadius+Vector3.up*(Mathf.Sin(a)*loopRadius+.025f);}sourceLoops[b].Update(.022f);source=sourceLoops[b].Points[14];
                Vector3 screen=cam.WorldToScreenPoint(source);float sx=(screen.x-safeRect.x)/safeRect.width,sy=(screen.y-safeRect.y)/safeRect.height;float side=sx<.5f?.015f:.985f;
                Vector3 bend=World(side,Mathf.Clamp(sy,.69f,.91f)),approach=World(side,.625f);if(sy<.78f){bend=World(sx,.668f);approach=World(.20f+block.Slot*.20f,.638f);}bend.y=.30f;approach.y=.32f;
                threads[b].Cubic(source,bend,approach,end,.033f);
            }
            lastAmount[b]=visualAmount;
            if(visible){slotLabels[block.Slot].text=counterText[Mathf.Clamp(block.Capacity-Mathf.FloorToInt(visualAmount),0,10)];slotLabels[block.Slot].color=Color.white;}else if(finished&&SlotHasNoActiveBlock(block.Slot))slotLabels[block.Slot].text="·";
        }
        bool SlotHasNoActiveBlock(int slot){for(int i=0;i<4;i++)if(Session.Blocks[i].Slot==slot&&Session.Blocks[i].Phase!=BlockPhase.Finished&&Session.Blocks[i].Phase!=BlockPhase.Board)return false;return true;}
        void PlaceText(Text text,Vector3 world){Vector3 screen=cam.WorldToScreenPoint(world);text.rectTransform.position=screen;}
        void BuildAudio(){audioSource=gameObject.GetComponent<AudioSource>()??gameObject.AddComponent<AudioSource>();float[] samples=new float[8820];for(int i=0;i<samples.Length;i++){float t=i/44100f;samples[i]=(Mathf.Sin(t*2*Mathf.PI*660)+.25f*Mathf.Sin(t*2*Mathf.PI*1320))*Mathf.Exp(-t*25)*.35f;}pluck=Own(AudioClip.Create("Original soft yarn pluck",samples.Length,1,44100,false));pluck.SetData(samples,0);}
        Text Label(string text,float x,float y,int size,Color color,TextAnchor alignment,float width,float height)
        {
            var go=new GameObject(text,typeof(RectTransform));go.transform.SetParent(safeUI,false);var r=go.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=new Vector2(x,y);r.sizeDelta=new Vector2(width,height);r.anchoredPosition=Vector2.zero;if(alignment==TextAnchor.MiddleLeft)r.pivot=new Vector2(0,.5f);
            var t=go.AddComponent<Text>();t.font=font;t.text=text;t.fontSize=size;t.color=color.linear;t.alignment=alignment;t.raycastTarget=false;t.supportRichText=true;t.horizontalOverflow=HorizontalWrapMode.Overflow;t.verticalOverflow=VerticalWrapMode.Overflow;return t;
        }
        RectTransform Panel(Transform parent,float x,float y,float w,float h,Color color)
        {
            var go=new GameObject("Soft panel",typeof(RectTransform));go.transform.SetParent(parent,false);var r=go.GetComponent<RectTransform>();r.anchorMin=r.anchorMax=new Vector2(x,y);r.anchoredPosition=Vector2.zero;r.sizeDelta=new Vector2(w,h);var im=go.AddComponent<Image>();im.color=color.linear;im.sprite=RoundedSprite();im.type=Image.Type.Sliced;return r;
        }
        static Sprite roundedSprite;
        static Sprite arrowSprite;
        static Sprite ArrowSprite(){if(arrowSprite)return arrowSprite;const int n=64;var t=new Texture2D(n,n,TextureFormat.RGBA32,false);var pixels=new Color[n*n];for(int y=0;y<n;y++)for(int x=0;x<n;x++){float d=Mathf.Abs(x-31.5f);bool inside=(y>=6&&y<36&&d<7)||(y>=30&&y<=57&&d<(58-y));pixels[y*n+x]=new Color(1,1,1,inside?1:0);}t.SetPixels(pixels);t.Apply();arrowSprite=Sprite.Create(t,new Rect(0,0,n,n),Vector2.one*.5f);return arrowSprite;}
        static Sprite RoundedSprite()
        {
            if(roundedSprite)return roundedSprite;const int n=64;var t=new Texture2D(n,n,TextureFormat.RGBA32,false);t.wrapMode=TextureWrapMode.Clamp;var pixels=new Color[n*n];
            for(int y=0;y<n;y++)for(int x=0;x<n;x++){float dx=Mathf.Max(Mathf.Abs(x-31.5f)-15.5f,0),dy=Mathf.Max(Mathf.Abs(y-31.5f)-15.5f,0);pixels[y*n+x]=new Color(1,1,1,Mathf.Clamp01(16-Mathf.Sqrt(dx*dx+dy*dy)));}t.SetPixels(pixels);t.Apply();roundedSprite=Sprite.Create(t,new Rect(0,0,n,n),Vector2.one*.5f,100,0,SpriteMeshType.FullRect,new Vector4(22,22,22,22));return roundedSprite;
        }
        Text Button(string title,float x,float y,float w,float h,UnityEngine.Events.UnityAction action)
        {
            var r=Panel(safeUI,x,y,w,h,WoolLabSettings.Hex("E5DCE8"));var b=r.gameObject.AddComponent<Button>();b.onClick.AddListener(action);var text=Label(title,x,y,22,settings.ink,TextAnchor.MiddleCenter,w,h);text.fontStyle=FontStyle.Bold;text.transform.SetParent(r,true);return text;
        }
    }
    public sealed class WoolBlockTag:MonoBehaviour {public int id;}
}




