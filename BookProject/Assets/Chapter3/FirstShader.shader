Shader "Unlit/FirstShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Color)] _Red("Red", Range(0, 1)) = 0
        _Green("Green", Range(0, 1)) = 0
        _Blue("Blue", Range(0, 1)) = 0
        _Alpha("Alpha", Range(0, 1)) = 0
    }
    SubShader
    {
         Tags {
             "Queue"="Transparent"
             "RenderType"="Transparent"
        }

        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "MyInc.cginc"
            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Red;
            float _Green;
            float _Blue;
            float _Alpha;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex + float3(0,2,0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(_Red,_Green,_Blue,_Alpha);
                col = OnlyRedAlpha(col);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
