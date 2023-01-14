Shader "Unlit/TestSH"
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
                float3 objectPos : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DirIntensity;

            float angleBetween(float3 colour, float3 original) {
                 return acos(dot(colour, original)/(length(colour)*length(original)));
             }

            
            float f(half a,half b,half c,half d,half e,half u)
            {
                half A = a * 1;
                half B = b * cos(u);
                half C = c * sin(u);
                half D = d * (2 * cos(u) * sin(u));
                half E = e * (2 * cos(u) * cos(u) - 1);
                return abs(A+B+C+D+E);

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.objectPos = v.vertex;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 求出顶点到原点的向量
                float3 point2Ori = normalize(i.worldPos.xyz - mul(unity_ObjectToWorld,half4(0,0,0,1)));
                half angle = angleBetween(half3(1,0,0),i.normal);

                return f(-0.6,0.1,0.2,-0.1,-0.2,angle);
                return f(0.6,0.2,0.3,0,0,angle);
            }
            ENDCG
        }
    }
}
