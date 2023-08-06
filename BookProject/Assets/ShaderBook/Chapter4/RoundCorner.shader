Shader "Chapter4/RoundCorner"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Radius("Radius", float) = 0.1
        _RoundSmooth("Round Smooth",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Radius;
            half _RoundSmooth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 scale = float2(
                    length(float3(unity_ObjectToWorld._m00_m10_m20)), 
                    length(float3(unity_ObjectToWorld._m01_m11_m21))
                );
                // 测算边缘距离
                half2 v = abs(i.uv-0.5)*scale-(0.5*scale-_Radius);
                half corner = 1-step(0,v.x)*step(0,v.y)*smoothstep(0,_RoundSmooth,(length(v)-_Radius)/_Radius);
                fixed4 col = tex2D(_MainTex, i.uv);
                return half4(col.rgb,corner);
            }
            ENDCG
        }
    }
}
