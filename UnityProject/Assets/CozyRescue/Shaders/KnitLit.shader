Shader "CozyRescue/KnitLit"
{
    Properties
    {
        _BaseColor("Yarn tint", Color) = (1,1,1,1)
        _BaseMap("Base", 2D) = "white" {}
        _BumpMap("Original knit normal", 2D) = "bump" {}
        _OcclusionMap("Original knit AO", 2D) = "white" {}
        _HasTextures("Baked stitch maps", Float) = 0
        _Stitches("Stitch columns", Float) = 16
        _BumpScale("Relief", Float) = .65
        _Smoothness("Smoothness", Float) = .18
        _Fuzz("Grazing fiber", Float) = .055
        _Unravel("Consumed fraction", Range(0,1)) = 0
        _AOFloor("Baked AO floor", Float) = .72
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
            TEXTURE2D(_OcclusionMap); SAMPLER(sampler_OcclusionMap);
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor, _BaseMap_ST;
            float _HasTextures, _Stitches, _BumpScale, _Smoothness, _Fuzz, _Unravel, _AOFloor;
            CBUFFER_END
            struct A { float4 positionOS:POSITION; float3 normalOS:NORMAL; float4 tangentOS:TANGENT; float2 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct V { float4 positionCS:SV_POSITION; float3 world:TEXCOORD0; float3 normal:TEXCOORD1; float4 tangent:TEXCOORD2; float2 uv:TEXCOORD3; UNITY_VERTEX_INPUT_INSTANCE_ID };
            V vert(A i) { V o; UNITY_SETUP_INSTANCE_ID(i); UNITY_TRANSFER_INSTANCE_ID(i,o); o.world=TransformObjectToWorld(i.positionOS.xyz); o.positionCS=TransformWorldToHClip(o.world); o.normal=TransformObjectToWorldNormal(i.normalOS); o.tangent=float4(TransformObjectToWorldDir(i.tangentOS.xyz),i.tangentOS.w*GetOddNegativeScale()); o.uv=i.uv; return o; }
            // Analytic original stitch relief also keeps prototypes textured while baked maps import.
            float relief(float2 uv)
            {
                float2 p=frac(uv*float2(_Stitches,_Stitches*.80));
                float x=abs(p.x-.5); float y=p.y;
                float d=abs(x-(.09+.34*y));
                float strand=exp(-d*d*270.0);
                float fibers=.93+.07*sin((p.x+p.y*.63)*130);
                return strand*fibers*(.82+.18*sin(y*3.14159));
            }
            half4 frag(V i):SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                clip(_Unravel>0?1-i.uv.y-_Unravel*.995:1);
                float h=relief(i.uv); float eps=.0007;
                float2 g=float2(relief(i.uv+float2(eps,0))-h,relief(i.uv+float2(0,eps))-h);
                float3 tn=normalize(float3(-g*_BumpScale*6,1));
                float ao=.73+.27*h;
                if(_HasTextures>.5) {
                    float2 tiled=i.uv*float2(_Stitches/4,_Stitches/4);
                    tn=UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,tiled),_BumpScale);
                    ao=lerp(.20,1,saturate((SAMPLE_TEXTURE2D(_OcclusionMap,sampler_OcclusionMap,tiled).r-_AOFloor)/max(.01,1-_AOFloor)));
                }
                float3 n=normalize(i.normal); float3 t=normalize(i.tangent.xyz); float3 b=cross(n,t)*i.tangent.w;
                n=normalize(t*tn.x+b*tn.y+n*tn.z);
                Light l=GetMainLight(TransformWorldToShadowCoord(i.world));
                float3 view=SafeNormalize(GetWorldSpaceViewDir(i.world));
                float ndl=saturate(dot(n,l.direction));
                float broad=saturate(dot(normalize(i.normal),l.direction)); float3 light=float3(.18,.20,.24)+l.color*(broad*.35+ndl*.70+.05)*lerp(.20,1,l.shadowAttenuation);
                float spec=pow(saturate(dot(n,SafeNormalize(l.direction+view))),lerp(12,42,_Smoothness))*.026*ndl;
                float grazing=pow(1-saturate(dot(n,view)),4)*_Fuzz;
                return half4(_BaseColor.rgb*light*ao+spec+_BaseColor.rgb*grazing,1);
            }
            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On ZTest LEqual ColorMask 0
            HLSLPROGRAM
            #pragma vertex shadowVert
            #pragma fragment shadowFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor, _BaseMap_ST;
            float _HasTextures, _Stitches, _BumpScale, _Smoothness, _Fuzz, _Unravel, _AOFloor;
            CBUFFER_END
            float3 _LightDirection;float3 _LightPosition;
            struct A{float4 positionOS:POSITION;float3 normalOS:NORMAL;float2 uv:TEXCOORD0;};
            struct V{float4 positionCS:SV_POSITION;float2 uv:TEXCOORD0;};
            V shadowVert(A i){V o;float3 p=TransformObjectToWorld(i.positionOS.xyz);float3 n=TransformObjectToWorldNormal(i.normalOS);
            #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
            float3 d=normalize(_LightPosition-p);
            #else
            float3 d=_LightDirection;
            #endif
            o.positionCS=TransformWorldToHClip(ApplyShadowBias(p,n,d));
            #if UNITY_REVERSED_Z
            o.positionCS.z=min(o.positionCS.z,UNITY_NEAR_CLIP_VALUE);
            #else
            o.positionCS.z=max(o.positionCS.z,UNITY_NEAR_CLIP_VALUE);
            #endif
            o.uv=i.uv;return o;}
            half4 shadowFrag(V i):SV_Target{clip(_Unravel>0?1-i.uv.y-_Unravel*.995:1);return 0;}
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ZWrite On ColorMask R
            HLSLPROGRAM
            #pragma vertex depthVert
            #pragma fragment depthFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor, _BaseMap_ST;
            float _HasTextures, _Stitches, _BumpScale, _Smoothness, _Fuzz, _Unravel, _AOFloor;
            CBUFFER_END
            struct A{float4 positionOS:POSITION;float2 uv:TEXCOORD0;};struct V{float4 positionCS:SV_POSITION;float2 uv:TEXCOORD0;};
            V depthVert(A i){V o;o.positionCS=TransformObjectToHClip(i.positionOS.xyz);o.uv=i.uv;return o;}
            half4 depthFrag(V i):SV_Target{clip(_Unravel>0?1-i.uv.y-_Unravel*.995:1);return i.positionCS.z;}
            ENDHLSL
        }
    }
}



