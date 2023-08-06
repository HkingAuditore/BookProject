Shader "Chapter4/TextureShader"
{
    Properties
    {
        [Header(Main Texture)]
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexRotation ("Main Texture Rotation", float) = 0
        
        [Header(Second Texture)]
        _SecondTex ("Second Texture", 2D) = "white" {}
        _SecondTexRotation ("Second Texture Rotation", float) = 0
        _MaskIntensity ("Mask Intensity", range(0,1)) = 0.5
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
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _SecondTex;
            float4 _SecondTex_ST;
            half _MainTexRotation;
            half _SecondTexRotation;
            
            half _MaskIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            half4 blend(half4 c0, half4 c1)
            {
                // fixed4 r =c0*(1-c1.a)+c1*(c1.a);//正常透明度混合
                
                // fixed4 r =min(c0,c1);//变暗
                //
                // fixed4 r =max(c0,c1);//变亮
                //
                // fixed4 r =c0*c1 ;//正片叠底
                //
                // fixed4 r=1-((1-c0)*(1-c1));//滤色 A+B-A*B
                //
                // fixed4 r =c0-((1-c0)*(1-c1))/c1; //颜色加深
                //
                // fixed4 r= c0+(c0*c1)/(1-c1); //颜色减淡
                //
                // fixed4 r=c0+c1-1;//线性加深
                //
                // fixed4 r=c0+c1; //线性减淡
                //
                // fixed4 f = step(c0,half4(0.5,0.5,0.5,0.5));
                // fixed4 r = f*c0*c1*2+(1-f)*(1-(1-c0)*(1-c1)*2);
                //叠加
                //
                // fixed4 f= step(c1,fixed4(0.5,0.5,0.5,0.5));
                //
                // fixed4 r=f*c0*c1*2+(1-f)*(1-(1-c0)*(1-c1)*2); //强光
                //
                // half4 f= step(c1,half4(0.5,0.5,0.5,0.5));
                //
                // half4 r=f*(c0*c1*2+c0*c0*(1-c1*2))+(1-f)*(c0*(1-c1)*2+sqrt(c0)*(2*c1-1)); //柔光
                //
                // half4 f= step(c1,half4(0.5,0.5,0.5,0.5));
                //
                // half4 r=f*(c0-(1-c0)*(1-2*c1)/(2*c1))+(1-f)*(c0+c0*(2*c1-1)/(2*(1-c1))); //亮光
                //
                // half4 f= step(c1,half4(0.5,0.5,0.5,0.5));
                
                // half4 r=f*(min(c0,2*c1))+(1-f)*(max(c0,( c1*2-1))); //点光 
                
                // half4 r=c0+2*c1-1; //线性光
                //
                // half4 f= step(c0+c1,half4(1,1,1,1));
                
                // half4 r=f*(half4(0,0,0,0))+(1-f)*(half4(1,1,1,1)); //实色混合
                //
                // half4 r=c0+c1-c0*c1*2; //排除
                //
                // half4 r=abs(c0-c1); //差值
                //
                // half4 f= step(c1.r+c1.g+c1.b,c0.r+c0.g+c0.b);
                //
                // half4 r=f*(c1)+(1-f)*(c0); //深色
                //
                // half4 f= step(c1.r+c1.g+c1.b,c0.r+c0.g+c0.b);
                //
                // half4 r=f*(c0)+(1-f)*(c1); //浅色
                //
                // half4 r = c0-c1; //减去
                //
                half4 r=c0/c1; //划分
                return r;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float sinxMain = sin(_MainTexRotation);
                float cosxMain = cos(_MainTexRotation);
                float2 uvRotatedMain = mul(i.uv,float2x2(cosxMain,-sinxMain,sinxMain,cosxMain));
                float2 uvForMainTex = TRANSFORM_TEX(uvRotatedMain, _MainTex);
                fixed4 col0 = tex2D(_MainTex, (i.uv+_MainTex_ST.zw)*_MainTex_ST.xy-_MainTex_ST.zw);
                float sinxSecond = sin(_SecondTexRotation);
                float cosxSecond = cos(_SecondTexRotation);
                float2 uvRotatedSecond = mul(float2x2(cosxSecond,-sinxSecond,sinxSecond,cosxSecond),i.uv);
                float2 uvForSecondTex = TRANSFORM_TEX(uvRotatedSecond, _SecondTex);
                fixed4 col1 = tex2D(_SecondTex, uvForSecondTex);
                
                float4 col = blend(half4(col0.rgb,0.5),half4(col1.rgb,0.5));
                return col0;
            }
            ENDCG
        }
    }
}
