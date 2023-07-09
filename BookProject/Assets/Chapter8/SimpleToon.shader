Shader "Chapter8/SimpleToon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp Texture", 2D) = "white" {}
        _CurveTex ("Curve Texture", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _LightColor("Light Color", Color) = (1, 1, 1, 1)
        _ShadowColor("Shadow Color", Color) = (1, 1, 1, 1)
        _SpecularColor("Spec Color", Color) = (1, 1, 1, 1)
        _OutlineColor("Outline Color", Color) = (1, 1, 1, 1)
        _ShadowIntensity("Shadow Intensity", Range(0,2)) = 0.5
        _Smoothness("_Smoothness",Range(0.01,1)) = 0.5
        _SpecIntensity("Spec Intensity", Range(0,1)) = 0.5
        _SpecPower("Spec Power", Range(0,1)) = 0.5
        
        _OutlineNoise ("Outline Noise", 2D) = "white" {}
        _OutlineWidth("Outline Width",Range(0,2)) = 0.01
        _OutlineCutoff("Outline Cutoff",Range(0,5)) = 0.01
        _OutlineNoisePower("Outline Noise Power",Range(0,1)) = 0.01
        
        _ShadeNoiseTex ("Shade Noise Texture", 2D) = "white" {}
        _ShadeNoiseIntensity ("Shade Noise Intensity",Range(0,1)) = 1
        
        _RimIntensity("Rim Intensity",Range(0,1)) = 1
        [HDR]_RimColor("Rim Color",Color) = (1, 1, 1, 1)
        _RimPower("Rim Power",Range(0,1)) = 1
        


    }
    SubShader
    {
        LOD 100

        Pass
        {
            Tags{
            	 "LightMode" = "ForwardBase"
            	 "Queue" = "Opaque"
            	}

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma vertex vert_myshaderlib
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"
            #include "MyShaderLib.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _ShadeNoiseTex;
            float4 _ShadeNoiseTex_ST;

            float4 _MainColor;
            float4 _LightColor;
            float4 _ShadowColor;
            float4 _SpecularColor;

            half _ShadowIntensity;
            half _Smoothness;
            half _SpecIntensity;
            half _SpecPower;

            half _ShadeNoiseIntensity;

            half _RimIntensity;
            half _RimPower;
            float4 _RimColor;

            // 映射关系仅有一个维度，因此使用sampler1D
            sampler1D _RampTex;

            
            

            fixed4 frag (v2f_myshaderlib i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                //笔刷
                half noise = pow(tex2D(_ShadeNoiseTex,(i.screenPos.xy/i.screenPos.w)*_ShadeNoiseTex_ST.xy)*3,1.5);

                // 漫反射
                half ndotl = dot(normal,lightDir);
                ndotl -= (1-ndotl)*noise*0.1*_ShadeNoiseIntensity;
                ndotl = smoothstep(-1,_ShadowIntensity,ndotl);
                

                // 高光反射
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfVector = normalize(lightDir+viewDir);
                half spec = dot(normal, halfVector);
                spec += (1-spec)*noise*0.1;
                spec = smoothstep(_SpecIntensity*_SpecPower,_SpecIntensity,spec);

                // 边缘光
                half rim = dot(normal,viewDir);
                rim += (1-rim)*noise*0.01;
                rim = 1-smoothstep(_RimIntensity,_RimIntensity+_RimPower,rim);
                
                // 漫反射采样Ramp图，高光直接指定颜色
                return lerp(tex1D(_RampTex,ndotl) * _MainColor + spec * _SpecularColor ,_RimColor, rim*_RimColor.a);
            }
            ENDCG
        }
        
        Pass
        {
            Cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 posObj : TEXCOORD2;
            };

            sampler2D _CurveTex;
            
            sampler2D _OutlineNoise;
            float4 _OutlineNoise_ST;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _OutlineWidth;
            float4 _OutlineColor;

            half _OutlineCutoff;

            v2f vert (appdata v)
            {
                v2f o;
                o.normal = normalize(mul(UNITY_MATRIX_MV, v.normal));
                o.posObj = v.vertex;
                o.vertex = mul(unity_MatrixMV,v.vertex);
                o.vertex /= o.vertex.w;
                o.uv = v.uv;

                half curve = pow(tex2Dlod(_CurveTex,half4(v.uv,0,0)),2);
                float width = _OutlineWidth * .01 * curve * -o.vertex.z / (unity_CameraProjection[1].y);
                width = sqrt(width);
                o.vertex.xy += o.normal.xy * width;
                o.vertex = mul(UNITY_MATRIX_P,o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float curve = length(fwidth(i.normal))/length(fwidth(i.posObj));
                half curve = pow(tex2D(_CurveTex,i.uv)*3,1.5);
                half2 viewPos = UnityObjectToViewPos(i.posObj);
                // half noise = tex2D(_OutlineNoise,viewPos*_OutlineNoise_ST.xy+_OutlineNoise_ST.zw);
                // clip(noise-_OutlineCutoff);
                return half4(_OutlineColor.rgb - curve * 3,1);
            }
            ENDCG
        }
        
        Pass
        {
           Tags{
               "Queue" = "Transparent"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 posObj : TEXCOORD2;
                float4 screenPos: TEXCOORD3;
            };

            sampler2D _CurveTex;
            
            sampler2D _OutlineNoise;
            float4 _OutlineNoise_ST;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _OutlineWidth;
            float4 _OutlineColor;

            half _OutlineCutoff;
            half _OutlineNoisePower;

            v2f vert (appdata v)
            {
                v2f o;
                o.normal = normalize(mul(UNITY_MATRIX_MV, v.normal));
                o.posObj = v.vertex;
                o.vertex = mul(unity_MatrixMV,v.vertex);
                o.vertex /= o.vertex.w;
                
                o.uv = v.uv;

                half2 viewPos = UnityObjectToViewPos(o.posObj);
                half noise = tex2Dlod(_OutlineNoise,half4(viewPos*_OutlineNoise_ST.xy+_OutlineNoise_ST.zw,0,0));

                half curve = pow(tex2Dlod(_CurveTex,half4(v.uv,0,0)),2);
                float width = _OutlineWidth * .01 * curve * -o.vertex.z / (unity_CameraProjection[1].y);
                width = sqrt(width)*1.5*(0.5+ noise);
                o.vertex.xy += o.normal.xy * width;
                o.vertex = mul(UNITY_MATRIX_P,o.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float curve = length(fwidth(i.normal))/length(fwidth(i.posObj));
                half curve = pow(tex2D(_CurveTex,i.uv)*3,1.5);
                
                half noise = tex2D(_OutlineNoise,i.screenPos.xy/i.screenPos.w*_OutlineNoise_ST.xy+_OutlineNoise_ST.zw);
                clip(noise-_OutlineCutoff);
                return half4(_OutlineColor.rgb - curve * 3,pow(noise-_OutlineCutoff,_OutlineNoisePower));
            }
            ENDCG
        }

    }
}
