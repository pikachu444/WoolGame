using UnityEngine;

namespace CozyRescue.Presentation
{
    [CreateAssetMenu(menuName = "Cozy Rescue/WoolLab Art Settings")]
    public sealed class WoolLabSettings : ScriptableObject
    {
        public Color[] yarnColors = { Hex("EF545B"), Hex("F2C340"), Hex("4EBB65"), Hex("428DDE") };
        public Color background = Hex("F4EDE2");
        public Color ink = Hex("514C67");
        [Range(.7f, 1.5f)] public float bodyWidth = 1.1f;
        [Range(.35f, .60f)] public float bodyPitch = .48f;
        [Range(.10f, .3f)] public float smoothness = .18f;
        [Range(8, 24)] public float stitchColumns = 16;
        [Range(.15f, 1.8f)] public float normalStrength = .65f;
        [Range(0, .3f)] public float fuzz = .055f;
        [Range(0, .4f)] public float pathSpeed = .13f;
        public Mesh cuffMesh;
        public GameObject dragonModel;
        public GameObject catModel;
        public Texture2D knitNormal;
        public Texture2D knitAO;
        public bool physicalKnit=true;
        public Font uiFont;
        public Sprite[] controlIcons;
        public Shader knitShader;
        public Shader surfaceShader;
        public static Color Hex(string hex) { ColorUtility.TryParseHtmlString("#" + hex, out Color c); return c; }
    }
}
