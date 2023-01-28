Shader "Unlit/Brush"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _ZoneSize("Zone Size" ,float) = 5
        _BrushSize("Brush Size" ,float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend One One
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            float4 _BrushPos;
            half _ZoneSize;
            half _BrushSize;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half2 pos =   (-_BrushPos.xz / _ZoneSize +1) * .5;
                half2 originUv = i.uv - pos;
                // uv的系数越大，圆点越小
                // 为了保证表现与参数调整的一致性，此处对brush size进行了倒数处理
                half traceMask = tex2D(_MaskTex,originUv * (1 / _BrushSize) + 0.5);
                return traceMask * 0.5;
            }
            ENDCG
        }
    }
}