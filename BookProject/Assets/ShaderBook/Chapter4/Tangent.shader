Shader "Chapter4/Tangent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBitangent : TEXCOORD3;
                float4 objectVertex : TEXCOORD4;
                
            };
            

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);  
                o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 计算副法线
                // 由于DirectX和OpenGL的UV走向不同，为了防止手性错误，此处需要乘以当前平台的手性值
                // v.tangent.w存储了当前平台的手性值
				o.worldBitangent = cross(o.worldNormal, o.worldTangent) * v.tangent.w;
                o.objectVertex = v.vertex;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {

                return half4(_SinTime.w,_CosTime.w,1,1);
            }
            ENDCG
        }
    }
}
