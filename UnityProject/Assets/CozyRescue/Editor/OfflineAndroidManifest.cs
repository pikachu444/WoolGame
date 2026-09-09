#if UNITY_ANDROID
using System.IO;
using System.Xml;
using UnityEditor.Android;

namespace CozyRescue.Editor
{
    // Unity may infer INTERNET from managed assemblies. This personal game has
    // no network feature, so the generated manifest must not request it.
    public sealed class OfflineAndroidManifest : IPostGenerateGradleAndroidProject
    {
        public int callbackOrder => 100;
        public void OnPostGenerateGradleAndroidProject(string path)
        {
            string manifest = Path.Combine(path, "src/main/AndroidManifest.xml");
            var xml = new XmlDocument();
            xml.Load(manifest);
            var ns = new XmlNamespaceManager(xml.NameTable);
            ns.AddNamespace("android", "http://schemas.android.com/apk/res/android");
            var nodes = xml.SelectNodes("/manifest/uses-permission[@android:name='android.permission.INTERNET']", ns);
            foreach (XmlNode node in nodes) node.ParentNode.RemoveChild(node);
            xml.Save(manifest);
            UnityEngine.Debug.Log("WOOL_OFFLINE_MANIFEST internet permission removed");
        }
    }
}
#endif
