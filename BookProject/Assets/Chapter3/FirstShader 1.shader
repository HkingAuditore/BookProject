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
                float4 pos : SV_POSITION;
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
                o.pos = UnityObjectToClipPos(v.vertex + float3(0,_Offset,0));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half Average(half a, half b)
            {
                return (a + b) * 0.5;
            }

            
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(_Red,_Green,_Blue,_Alpha);
                col = OnlyRedAlpha(col);

                
                
                
                

                float a = 1;
                float b = 2;
                float c = 3;
                float abAverage = Average(a,b);
                float acAverage = Average(a,c);
                float bcAverage = Average(b,c);


                half2x2 m = half2x2(0,0.25,
                                    0.75,1);

                m[1][0] = 0;
                half n00 = m[0][0];   //返回0
                half n01 = m[0][1];   //返回0.25
                half n10 = m[1][0];   //返回0.75
                half n11 = m[0][1];   //返回1
                half n = n10;
                return half4(n,n,n ,1);
                
                

                
                col = col * sin(i.pos.x);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
                
            }
            ENDCG
        }
    }
}
