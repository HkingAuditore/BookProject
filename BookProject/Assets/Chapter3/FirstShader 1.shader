Shader "Unlit/FirstShader2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Color)] _Red("Red", Range(0, 1)) = 0
        _Green("Green", Range(0, 1)) = 0
        _Blue("Blue", Range(0, 1)) = 0
        _Alpha("Alpha", Range(0, 1)) = 0
        [Header(Offset)] _Offset("Offset", float) = 0
    }
    SubShader
    {
         Tags {
             "Queue"="Transparent"
             "RenderType"="Transparent"
        }
         LOD 100
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
            
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Red;
            float _Green;
            float _Blue;
            float _Alpha;
            float _Offset;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex + float3(0,_Offset,0));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(_Red,_Green,_Blue,_Alpha);
                col = OnlyRedAlpha(col);

                float a = 1;
                float b = 0;
                if(a > 0)
                {
                    b = 1;
                }else
                {
                    b = -1;
                }
                b += 1;
                
                col = col * sin(i.vertex.x);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
