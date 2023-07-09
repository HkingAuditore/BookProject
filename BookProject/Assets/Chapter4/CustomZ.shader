Shader "Chapter4/CustomZ"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1)
        [Header(A group of things)] _Prop1 ("Prop1", Float) = 0
    }
    SubShader
    {
//        Tags { "Queue"="AlphaTest" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            half4 _Color;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = v.vertex;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {

                // 世界空间y<0的区域返回-1，y>0区域返回1
                half y = (step(0,i.worldPos.y)-0.5)*2;
                clip(y);
                return _Color;
            }
            ENDCG
        }
    }
}
