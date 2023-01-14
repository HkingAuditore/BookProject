// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/DiffrentSpaces"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LineWidth ("Line Width", Range(0,0.1)) = 0.05
        _LineGap ("Line Gap", Range(0,0.5)) = 0.1
        _WorldSpaceIntensity ("_World Space Intensity", Range(0,1)) = 0
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
            float _LineWidth;
            float _LineGap;
            float _WorldSpaceIntensity;


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 objectPos : TEXCOORD2;
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = UnityObjectToClipPos(v.vertex);
                // o.vertex =mul(mul(mul(v.vertex,UNITY_MATRIX_M),UNITY_MATRIX_V),UNITY_MATRIX_P);
                o.pos =UnityObjectToClipPos(v.vertex);
                
                
                
                o.objectPos = v.vertex;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float ScanEffect(float v, float lineWidth, float gap)
            {
                // 使用frac函数取值的小数部分
                float p =  frac(v / (lineWidth+gap)) * (lineWidth+gap);
                // 使用step将结果二值化，p小于gap返回0，否则返回1
                return step(gap, p);
            }

            half IsVisable(float4 v)
            {
                return v.z;
                return (step(-v.w,v.x) - step(v.w,v.x))*
                    (step(-v.w,v.y) - step(v.w,v.y))*
                    (step(-v.w,v.z) - step(v.w,v.z));
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // float objSpace = ScanEffect(i.objectPos.y,_LineWidth,_LineGap);
                // float worldSpace = ScanEffect(i.worldPos.y,_LineWidth,_LineGap);
                // 使用lerp函数调整使用的空间
                // 当_WorldSpaceIntensity为0时，显示objSpace
                // 当_WorldSpaceIntensity为1时，显示worldSpace
                
                // 当前片元到模型原点的向量,转为世界空间
                half4 v = mul(unity_ObjectToWorld,float4(normalize(i.objectPos - float3(0,0,0)),0));
                half4 worldYAxis = float4(0,1,0,0);
                
                // 求夹角的cos值
                half cos = dot(v,worldYAxis)/(length(v)*length(worldYAxis));
                // 通过二值化相减计算插值
                half4 col = step(0.49,cos) - step(0.51,cos);

                // float4 pPos = UnityObjectToClipPos(float4(0,0,0,1));
                // float4 col = smoothstep(1,0,abs(pPos.x/pPos.w)) * smoothstep(1,0,abs(pPos.y/pPos.w));
                return col;
                
            }
            ENDCG
        }
    }
}
