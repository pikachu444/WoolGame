using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CozyRescue.Presentation
{
    public static class WoolGeometry
    {
        public static Mesh Tray(Vector3 size,float corner=.45f)
        {
            const int steps=10,count=44;float bevel=Mathf.Min(.09f,size.y*.35f);var vertices=new List<Vector3>();var uv=new List<Vector2>();var triangles=new List<int>();
            for(int ring=0;ring<4;ring++){
                float inset=ring==0||ring==3?bevel:0;float y=ring==0?-size.y*.5f:ring==1?-size.y*.5f+bevel:ring==2?size.y*.5f-bevel:size.y*.5f;
                for(int c=0;c<4;c++)for(int j=0;j<=steps;j++){float a=(c*90+j*90f/steps)*Mathf.Deg2Rad;float sx=c==0||c==3?1:-1,sz=c<2?1:-1;float r=corner-inset;
                    var p=new Vector3(sx*(size.x*.5f-corner)+Mathf.Cos(a)*r,y,sz*(size.z*.5f-corner)+Mathf.Sin(a)*r);vertices.Add(p);uv.Add(new Vector2(p.x,p.z));}
            }
            for(int ring=0;ring<3;ring++)for(int j=0;j<count;j++){int a=ring*count+j,b=ring*count+(j+1)%count,c=a+count,d=b+count;triangles.AddRange(new[]{a,c,b,b,c,d});}
            int top=vertices.Count;vertices.Add(new Vector3(0,size.y*.5f,0));uv.Add(Vector2.zero);for(int j=0;j<count;j++)triangles.AddRange(new[]{top,3*count+(j+1)%count,3*count+j});
            var mesh=new Mesh{name="Original padded rounded tray"};mesh.SetVertices(vertices);mesh.SetUVs(0,uv);mesh.SetTriangles(triangles,0);mesh.RecalculateNormals();mesh.RecalculateTangents();mesh.RecalculateBounds();return mesh;
        }
        public static Mesh RoundedBox(Vector3 size, float radius, int steps = 6,float uvUnit=1)
        {
            // A thin textile overlay cannot have a spherical bevel thicker than
            // its half-height: negative inner extents turn the top face inward.
            radius=Mathf.Min(radius,Mathf.Min(size.x,Mathf.Min(size.y,size.z))*.499f);
            var vertices = new List<Vector3>(); var uv = new List<Vector2>(); var indices = new List<int>();
            Vector3[] normals={Vector3.right,Vector3.left,Vector3.up,Vector3.down,Vector3.forward,Vector3.back};
            foreach(var n in normals)
            {
                Vector3 u = Mathf.Abs(n.y)>.5f?Vector3.right:Vector3.Cross(Vector3.up,n);
                Vector3 v=Vector3.Cross(n,u); int start=vertices.Count;
                for(int y=0;y<=steps;y++) for(int x=0;x<=steps;x++)
                {
                    Vector3 unit=n*.5f+u*((float)x/steps-.5f)+v*((float)y/steps-.5f);
                    Vector3 p=Vector3.Scale(unit,size); Vector3 inner=size*.5f-Vector3.one*radius;
                    Vector3 q=new Vector3(Mathf.Clamp(p.x,-inner.x,inner.x),Mathf.Clamp(p.y,-inner.y,inner.y),Mathf.Clamp(p.z,-inner.z,inner.z));
                    vertices.Add(q+(p-q).normalized*radius);float w=Mathf.Abs(u.x)*size.x+Mathf.Abs(u.y)*size.y+Mathf.Abs(u.z)*size.z,h=Mathf.Abs(v.x)*size.x+Mathf.Abs(v.y)*size.y+Mathf.Abs(v.z)*size.z;uv.Add(new Vector2((float)x/steps*w/uvUnit,(float)y/steps*h/uvUnit));
                }
                for(int y=0;y<steps;y++) for(int x=0;x<steps;x++) {int a=start+y*(steps+1)+x;indices.AddRange(new[]{a,a+1,a+steps+2,a,a+steps+2,a+steps+1});}
            }
            Mesh mesh=new Mesh{name="Original rounded textile block"};mesh.SetVertices(vertices);mesh.SetUVs(0,uv);mesh.SetTriangles(indices,0);mesh.RecalculateNormals();mesh.RecalculateTangents();mesh.RecalculateBounds();return mesh;
        }

        public static Mesh Cuff()
        {
            // Authored scalloped, stuffed four-leaf silhouette; imported Blender mesh replaces this.
            const int rings=12, sides=32; var vs=new List<Vector3>();var uv=new List<Vector2>();var ts=new List<int>();
            for(int r=0;r<=rings;r++) { float v=(float)r/rings;float phi=v*Mathf.PI;float s=Mathf.Sin(phi);
                for(int j=0;j<=sides;j++) {float u=(float)j/sides;float a=u*Mathf.PI*2;float edge=1+.17f*Mathf.Cos(a*4);
                    vs.Add(new Vector3(Mathf.Cos(a)*.46f*s*edge,Mathf.Cos(phi)*.16f,Mathf.Sin(a)*.31f*s*edge)); uv.Add(new Vector2(u,v));
                }
            }
            for(int r=0;r<rings;r++)for(int j=0;j<sides;j++){int a=r*(sides+1)+j;ts.AddRange(new[]{a,a+1,a+sides+1,a+1,a+sides+2,a+sides+1});}
            var m=new Mesh{name="Original cloud cuff"};m.SetVertices(vs);m.SetUVs(0,uv);m.SetTriangles(ts,0);m.RecalculateNormals();m.RecalculateTangents();return m;
        }

        public static GameObject MeshObject(string name, Transform parent, Mesh mesh, Material mat, Vector3 pos, Vector3 scale)
        {
            var go=new GameObject(name);go.transform.SetParent(parent,false);go.transform.localPosition=pos;go.transform.localScale=scale;
            go.AddComponent<MeshFilter>().sharedMesh=mesh;var r=go.AddComponent<MeshRenderer>();r.sharedMaterial=mat;return go;
        }
    }

    public sealed class WoolTube
    {
        readonly Mesh mesh; readonly Vector3[] vertices;readonly Vector3[] normals;readonly Vector4[] tangents;readonly Vector2[] uv; readonly int[] triangles;
        public readonly GameObject GameObject;
        public readonly Vector3[] Points;
        readonly int sides;
        public WoolTube(string name,Transform parent,Material material,int samples=40,int radial=8)
        {
            sides=radial;Points=new Vector3[samples];vertices=new Vector3[samples*radial];normals=new Vector3[vertices.Length];tangents=new Vector4[vertices.Length];uv=new Vector2[vertices.Length];triangles=new int[(samples-1)*radial*6];
            int k=0;for(int i=0;i<samples-1;i++)for(int j=0;j<radial;j++){int a=i*radial+j,b=i*radial+(j+1)%radial,c=a+radial,d=b+radial;triangles[k++]=a;triangles[k++]=b;triangles[k++]=c;triangles[k++]=b;triangles[k++]=d;triangles[k++]=c;}
            mesh=new Mesh{name=name};mesh.MarkDynamic();mesh.vertices=vertices;mesh.triangles=triangles;
            GameObject=WoolGeometry.MeshObject(name,parent,mesh,material,Vector3.zero,Vector3.one);
            GameObject.GetComponent<MeshRenderer>().shadowCastingMode=ShadowCastingMode.Off;
        }
        public void Cubic(Vector3 a,Vector3 b,Vector3 c,Vector3 d,float radius)
        {
            for(int i=0;i<Points.Length;i++){float t=(float)i/(Points.Length-1),q=1-t;Points[i]=q*q*q*a+3*q*q*t*b+3*q*t*t*c+t*t*t*d;} Update(radius);
        }
        public void Update(float radius)
        {
            float length=0;Vector3 previousNormal=Vector3.up;
            for(int i=0;i<Points.Length;i++)
            {
                Vector3 tangent=(Points[Mathf.Min(i+1,Points.Length-1)]-Points[Mathf.Max(0,i-1)]).normalized;
                if(tangent.sqrMagnitude<.1f)tangent=Vector3.right;
                Vector3 n=Vector3.ProjectOnPlane(previousNormal,tangent).normalized;if(n.sqrMagnitude<.1f)n=Vector3.Cross(tangent,Vector3.forward).normalized;
                Vector3 b=Vector3.Cross(tangent,n);previousNormal=n;if(i>0)length+=Vector3.Distance(Points[i],Points[i-1]);
                for(int j=0;j<sides;j++){float a=j*2*Mathf.PI/sides;Vector3 radial=n*Mathf.Cos(a)+b*Mathf.Sin(a),around=-n*Mathf.Sin(a)+b*Mathf.Cos(a);int at=i*sides+j;vertices[at]=Points[i]+radius*radial;normals[at]=radial;tangents[at]=new Vector4(around.x,around.y,around.z,1);uv[at]=new Vector2((float)j/sides,length*3);}
            }
            mesh.vertices=vertices;mesh.normals=normals;mesh.tangents=tangents;mesh.uv=uv;mesh.RecalculateBounds();
        }
        public void Dispose(){if(Application.isPlaying)Object.Destroy(mesh);else Object.DestroyImmediate(mesh);}
    }

    public sealed class WoolPath
    {
        readonly Vector3[] points;readonly float[] lengths; public float Length{get;private set;}
        public WoolPath(Vector3[] controls)
        {
            const int resolution=160;points=new Vector3[resolution];lengths=new float[resolution];
            for(int i=0;i<resolution;i++){float f=(float)i/(resolution-1)*(controls.Length-1);int s=Mathf.Min((int)f,controls.Length-2);float t=f-s;
                Vector3 a=controls[Mathf.Max(0,s-1)],b=controls[s],c=controls[s+1],d=controls[Mathf.Min(controls.Length-1,s+2)];
                points[i]=.5f*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t);
                if(i>0)Length+=Vector3.Distance(points[i],points[i-1]);lengths[i]=Length;
            }
        }
        public Vector3 At(float distance)
        {
            distance=Mathf.Clamp(distance,0,Length);int lo=0,hi=points.Length-1;while(hi-lo>1){int m=(lo+hi)/2;if(lengths[m]<distance)lo=m;else hi=m;}
            return Vector3.Lerp(points[lo],points[hi],Mathf.InverseLerp(lengths[lo],lengths[hi],distance));
        }
        public Quaternion Rotation(float distance){Vector3 t=At(distance+.025f)-At(distance-.025f);return t.sqrMagnitude<.00001f?Quaternion.identity:Quaternion.LookRotation(t,Vector3.up);}
    }
}
