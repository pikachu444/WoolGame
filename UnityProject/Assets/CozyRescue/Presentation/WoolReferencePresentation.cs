using UnityEngine;
using UnityEngine.UI;
using CozyRescue.Demo;

namespace CozyRescue.Presentation
{
    public sealed partial class WoolLab
    {
        Text speedIndicator;
        void TogglePlaybackSpeed(){playbackSpeed=playbackSpeed==1?.5f:1;speedIndicator.text=playbackSpeed==1?"1×":"0.5×";speedLabel.text=playbackSpeed==1?"0.5×":"1×";}
        void ModalControl(Text caption,Transform parent,Vector2 position)
        {
            var group=(RectTransform)caption.transform.parent.parent;
            group.SetParent(parent,false);group.anchorMin=group.anchorMax=Vector2.one*.5f;group.anchoredPosition=position;
            foreach(RectTransform child in group){child.anchorMin=child.anchorMax=Vector2.one*.5f;child.anchoredPosition=new Vector2(0,child.GetComponent<Button>()?2:-5);}
            caption.rectTransform.anchorMin=caption.rectTransform.anchorMax=Vector2.one*.5f;caption.rectTransform.anchoredPosition=Vector2.zero;
        }
        void BuildStage()
        {
            var upper=World(.5f,.85f);upper.y=-.28f;
            WoolGeometry.MeshObject("Knitted upper play field",stage,box,Linen(WoolLabSettings.Hex("A6C5DD"),36),upper,new Vector3(16,.12f,Vector3.Distance(World(.5f,.66f),World(.5f,1.1f))));
            Vector3[] curve={World(.81f,1.055f),World(.49f,.945f),World(.72f,.877f),World(.91f,.806f),World(.81f,.728f),World(.50f,.705f),World(.19f,.720f),World(.055f,.785f)};
            path=new WoolPath(curve);
            var ribbon=OwnTube(new WoolTube("Stitched inset route",stage,Linen(WoolLabSettings.Hex("8DAFCA"),18),150,10));
            for(int i=0;i<ribbon.Points.Length;i++){var point=path.At(i/(float)(ribbon.Points.Length-1)*path.Length);point.y=0;ribbon.Points[i]=point;}
            ribbon.Update(.48f);ribbon.GameObject.transform.localScale=new Vector3(1,.08f,1);ribbon.GameObject.transform.position=Vector3.down*.25f;
            for(int side=-1;side<=1;side+=2){var seam=OwnTube(new WoolTube("Route embroidered edge",stage,Lit(WoolLabSettings.Hex("C9DBE7"),.02f),150,4));for(int i=0;i<150;i++){float d=i/149f*path.Length;seam.Points[i]=path.At(d)+path.Rotation(d)*Vector3.right*(side*.43f)+Vector3.down*.20f;}seam.Update(.017f);}
            for(int i=0;i<24;i++){int color=i<4?0:i<8?1:i<14?2:3;units[i]=WoolGeometry.MeshObject("Knit unit "+i,stage,cuff,yarn[color],Vector3.zero,Vector3.one*settings.bodyWidth).transform;}
            dragon=MakeActor(settings.dragonModel,true);dragonScale=Vector3.one*settings.bodyWidth*1.12f;dragon.localScale=dragonScale;
            cat=MakeActor(settings.catModel,false);cat.localScale=Vector3.one*1.20f;catHome=World(.50f,.800f);catHome.y=.0f;cat.position=catHome;cat.rotation=Quaternion.Euler(0,180,0);
            wavingPaw=FindPart(cat,"wavepaw");eyeLeft=FindPart(cat,"eyel");eyeRight=FindPart(cat,"eyer");if(eyeLeft)eyeLeftScale=eyeLeft.localScale;if(eyeRight)eyeRightScale=eyeRight.localScale;if(wavingPaw)pawRest=wavingPaw.localRotation;
            var shelf=World(.5f,.600f);shelf.y=-.22f;
            WoolGeometry.MeshObject("Four spool collection strip",stage,box,Lit(WoolLabSettings.Hex("97BCD4"),.08f),shelf,new Vector3(15,.12f,2.0f));
            for(int i=0;i<4;i++){var seat=World(.20f+i*.2f,.598f);seat.y=-.12f;WoolGeometry.MeshObject("Recessed collection slot "+i,stage,Own(WoolGeometry.Tray(new Vector3(1.90f,.07f,.84f),.13f)),Lit(WoolLabSettings.Hex("789AB8"),.1f),seat,Vector3.one);}
            int[][] footprints={new[]{2,3,1,1},new[]{0,2,1,1},new[]{1,1,1,2},new[]{0,0,3,1}};
            for(int i=0;i<4;i++){
                int[] f=footprints[i];Vector3 start=Grid(f[0]+(f[2]-1)*.5f,f[1]+(f[3]-1)*.5f);start.y=-.05f;blockStart[i]=start;
                float w=Vector3.Distance(Grid(0,0),Grid(1,0)),h=Vector3.Distance(Grid(0,0),Grid(0,1));var size=new Vector3(w*f[2]-.14f,.57f,h*f[3]-.14f);
                blocks[i]=WoolGeometry.MeshObject("Direction block "+i,stage,Own(WoolGeometry.RoundedBox(size,.17f,8,settings.bodyWidth)),yarn[i],start,Vector3.one).transform;
                var edgeMat=MakeYarn(Color.Lerp(settings.yarnColors[i],Color.white,.20f));edgeMat.SetFloat("_Stitches",7);
                var rimSize=new Vector3(size.x+.035f,.075f,size.z+.035f);WoolGeometry.MeshObject("Soft colored binding",blocks[i],Own(WoolGeometry.RoundedBox(rimSize,.15f,8,settings.bodyWidth)),edgeMat,new Vector3(0,.30f,0),Vector3.one);
                var faceSize=new Vector3(size.x-.19f,.045f,size.z-.19f);var faceMat=MakeYarn(settings.yarnColors[i]);faceMat.SetFloat("_Stitches",5);
                WoolGeometry.MeshObject("Deep knit face",blocks[i],Own(WoolGeometry.RoundedBox(faceSize,.10f,6,settings.bodyWidth)),faceMat,new Vector3(0,.32f,0),Vector3.one);
                var collider=blocks[i].gameObject.AddComponent<BoxCollider>();collider.size=size;blocks[i].gameObject.AddComponent<WoolBlockTag>().id=i;
                spools[i]=new GameObject("Working spool "+i).transform;spools[i].SetParent(stage,false);var spoolMaterial=Lit(settings.yarnColors[i],.3f);
                WoolGeometry.MeshObject("Colored spool spindle",spools[i],box,spoolMaterial,Vector3.zero,new Vector3(1.12f,.24f,.24f));
                for(int side=-1;side<=1;side+=2){var disc=GameObject.CreatePrimitive(PrimitiveType.Cylinder);disc.name="Colored spool flange";disc.transform.SetParent(spools[i],false);disc.transform.localPosition=new Vector3(side*.59f,0,0);disc.transform.localRotation=Quaternion.Euler(0,0,90);disc.transform.localScale=new Vector3(.74f,.075f,.74f);disc.GetComponent<Renderer>().sharedMaterial=spoolMaterial;Destroy(disc.GetComponent<Collider>());}
                coils[i]=OwnTube(new WoolTube("Wound yarn "+i,stage,yarn[i],112,6));threads[i]=OwnTube(new WoolTube("Traveling yarn "+i,stage,yarn[i],42,8));woundBodies[i]=OwnTube(new WoolTube("Wound core "+i,stage,yarn[i],3,16));sourceLoops[i]=OwnTube(new WoolTube("Unraveling edge "+i,stage,yarn[i],15,6));
            }
        }
        Text GameText(string value,float x,float y,int size,Color color,float width=240,float height=50)
        {var t=Label(value,x,y,size,color,TextAnchor.MiddleCenter,width,height);t.fontStyle=FontStyle.Bold;var outline=t.gameObject.AddComponent<Outline>();outline.effectColor=new Color(.13f,.15f,.18f,.85f);outline.effectDistance=new Vector2(1.2f,-1.2f);return t;}
        Text GameButton(string caption,float x,float y,float w,float h,UnityEngine.Events.UnityAction action,bool icon=false)
        {
            var shadow=Panel(safeUI,x,y-.004f,w+7,h+7,WoolLabSettings.Hex("846B40"));
            var rim=Panel(safeUI,x,y,w+7,h+7,WoolLabSettings.Hex("EAA933"));var face=Panel(safeUI,x,y+.002f,w,h,WoolLabSettings.Hex("FFF2BF"));
            shadow.SetParent(rim,true);face.SetParent(rim,true);shadow.SetAsFirstSibling();var b=face.gameObject.AddComponent<Button>();b.onClick.AddListener(action);
            var text=Label(caption,x,y+.002f,icon?37:22,WoolLabSettings.Hex("5B452B"),TextAnchor.MiddleCenter,w,h);text.fontStyle=FontStyle.Bold;text.transform.SetParent(face,true);return text;
        }
        void BuildUI()
        {
            font=settings.uiFont?settings.uiFont:Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var root=new GameObject("Rebuilt game interface");root.transform.SetParent(stage,false);canvas=root.AddComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;root.AddComponent<GraphicRaycaster>();var scaler=root.AddComponent<CanvasScaler>();scaler.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=new Vector2(720,1560);scaler.matchWidthOrHeight=.5f;
            safeUI=new GameObject("Safe Area",typeof(RectTransform)).GetComponent<RectTransform>();safeUI.SetParent(root.transform,false);safeUI.anchorMin=Vector2.zero;safeUI.anchorMax=Vector2.one;safeUI.offsetMin=safeUI.offsetMax=Vector2.zero;
            GameButton("Ⅱ",.075f,.952f, sixty, sixty,TogglePause,true);
            GameText("1단계",.075f,.907f,20,Color.white,100,40);
            progress=GameText("0 / 24",.50f,.959f,21,Color.white,180,40);
            speedIndicator=GameButton(playbackSpeed==1?"1×":"0.5×",.915f,.952f,72,49,TogglePlaybackSpeed,false);
            for(int i=0;i<3;i++)GameText("♥",.465f+i*.035f,.876f,24,WoolLabSettings.Hex("F65D4E"),35,35);
            var line=Panel(safeUI,.5f,.653f,900,2,new Color(1,1,1,.75f));line.GetComponent<Image>().raycastTarget=false;
            for(int i=0;i<4;i++){
                slotLabels[i]=GameText("·",.20f+i*.2f,.566f,25,Color.white,90,40);
                blockLabels[i]=GameText("",.5f,.5f,22,Color.white,105,105);blockLabels[i].alignment=TextAnchor.LowerRight;
                var arrow=new GameObject("Direction arrow",typeof(RectTransform),typeof(Image),typeof(Outline));var r=arrow.GetComponent<RectTransform>();r.SetParent(blockLabels[i].transform,false);r.anchorMin=r.anchorMax=new Vector2(.5f,.66f);r.anchoredPosition=Vector2.zero;r.sizeDelta=new Vector2(40,i==2?91:i==3?149:49);r.localRotation=Quaternion.Euler(0,0,-90*i);var image=arrow.GetComponent<Image>();image.sprite=ArrowSprite();image.raycastTarget=false;var outline=arrow.GetComponent<Outline>();outline.effectColor=new Color(.1f,.15f,.18f,.8f);outline.effectDistance=new Vector2(1.5f,-1.5f);
            }
            status=Label("화살표 방향으로 블록을 꺼내 주세요",.5f,.16f,19,WoolLabSettings.Hex("52778B"),TextAnchor.MiddleCenter,670,40);
            pauseLabel=GameButton("잠깐",.22f,.079f,133,91,TogglePause);var replayButton=GameButton("다시 보기",.50f,.079f,133,91,Replay);speedLabel=GameButton("0.5×",.78f,.079f,133,91,TogglePlaybackSpeed);
            DecorateControl(pauseLabel,0);DecorateControl(replayButton,1);DecorateControl(speedLabel,2);
            pausePanel=Panel(safeUI,.5f,.42f,590,370,WoolLabSettings.Hex("FFF1C5")).gameObject;
            var heading=GameText("잠시 쉬어 가요",.5f,.49f,30,Color.white,510,60);heading.transform.SetParent(pausePanel.transform,false);heading.rectTransform.anchorMin=heading.rectTransform.anchorMax=Vector2.one*.5f;heading.rectTransform.anchoredPosition=new Vector2(0,120);
            var resume=GameButton("계속하기",.5f,.42f,220,70,TogglePause);ModalControl(resume,pausePanel.transform,new Vector2(0,5));
            soundLabel=GameButton("소리 꺼짐",.33f,.35f,165,55,()=>{muted=!muted;soundLabel.text=muted?"소리 꺼짐":"소리 켜짐";});ModalControl(soundLabel,pausePanel.transform,new Vector2(-115,-100));
            hapticLabel=GameButton("진동 꺼짐",.67f,.35f,165,55,()=>{haptic=!haptic;hapticLabel.text=haptic?"진동 켜짐":"진동 꺼짐";});ModalControl(hapticLabel,pausePanel.transform,new Vector2(115,-100));pausePanel.SetActive(false);
            successPanel=Panel(safeUI,.5f,.39f,560,230,WoolLabSettings.Hex("FFF0B9")).gameObject;
            var win=GameText("구조 성공!",.5f,.418f,40,Color.white,520,70);win.transform.SetParent(successPanel.transform,true);
            var message=Label("고양이를 구했어요",.5f,.365f,24,WoolLabSettings.Hex("7F6437"),TextAnchor.MiddleCenter,510,55);message.transform.SetParent(successPanel.transform,true);successPanel.SetActive(false);
            for(int i=0;i<5;i++){rescueHearts[i]=GameText("♥",.5f,.80f,23,WoolLabSettings.Hex("F46055"),35,35);rescueHearts[i].gameObject.SetActive(false);}
            if(UnityEngine.EventSystems.EventSystem.current==null){var e=new GameObject("Input Event System");e.AddComponent<UnityEngine.EventSystems.EventSystem>();e.AddComponent<UnityEngine.InputSystem.UI.InputSystemUIInputModule>();}
        }
        void DecorateControl(Text caption,int kind)
        {
            var rt=caption.rectTransform;rt.anchorMin=rt.anchorMax=new Vector2(.5f,.5f);rt.anchoredPosition=new Vector2(0,-29);rt.sizeDelta=new Vector2(130,27);caption.fontSize=18;
            var image=new GameObject("Control symbol",typeof(RectTransform),typeof(Image)).GetComponent<Image>();image.transform.SetParent(caption.transform.parent,false);var ir=image.rectTransform;ir.anchorMin=ir.anchorMax=Vector2.one*.5f;ir.anchoredPosition=new Vector2(0,12);ir.sizeDelta=new Vector2(53,53);image.raycastTarget=false;
            if(settings.controlIcons!=null&&settings.controlIcons.Length>kind&&settings.controlIcons[kind]){image.sprite=settings.controlIcons[kind];return;}
            const int n=96;var tex=Own(new Texture2D(n,n,TextureFormat.RGBA32,false));var pixels=new Color[n*n];Color tint=WoolLabSettings.Hex(kind==0?"3194CF":kind==1?"E86A35":"65AC50");
            for(int y=0;y<n;y++)for(int x=0;x<n;x++){float px=(x-47.5f)/40,py=(y-47.5f)/40,r=Mathf.Sqrt(px*px+py*py);bool hit=false;
                if(kind==0)hit=Mathf.Abs(py)<.77f&&(Mathf.Abs(px-.38f)<.19f||Mathf.Abs(px+.38f)<.19f);
                if(kind==1)hit=(r>.43f&&r<.82f&&!(px>.1f&&py>.3f))||(px>.20f&&px<.86f&&py>.02f&&py<.69f&&py>1.15f*px-.55f);
                if(kind==2)hit=(px>-.82f&&px<.12f&&Mathf.Abs(py)<(.15f-px)*.82f)||(px>-.05f&&px<.88f&&Mathf.Abs(py)<(.90f-px)*.82f);
                float shade=.7f+.3f*(py*.5f+.5f);pixels[y*n+x]=hit?new Color(tint.r*shade,tint.g*shade,tint.b*shade,1):Color.clear;
            }
            tex.SetPixels(pixels);tex.Apply();image.sprite=Own(Sprite.Create(tex,new Rect(0,0,n,n),Vector2.one*.5f));var outline=image.gameObject.AddComponent<Outline>();outline.effectColor=new Color(.30f,.20f,.10f,1);outline.effectDistance=new Vector2(1,-1);
        }
        const float sixty=60;
    }
}
