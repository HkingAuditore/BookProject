Shader "Unlit/TwoNormals"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DirIntensity("Dir Intensity", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float3 color : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DirIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 求出顶点到原点的向量
                float3 point2Ori = normalize(float3(0,0,0) - i.worldPos.xyz);
                half dir = dot(point2Ori,i.normal);
                dir = smoothstep(_DirIntensity,1,dir);

                return dir;
            }
            ENDCG
        }
    }
}
