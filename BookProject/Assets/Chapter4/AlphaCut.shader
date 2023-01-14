Shader "Unlit/AlphaCut"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff("Cutoff", range(0,1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="AlphaTest" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            half4 _Color;
            half _Cutoff;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                clip(col - _Cutoff);
                return _Color;
            }
            ENDCG
        }
    }
}
