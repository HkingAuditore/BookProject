Shader "Chapter5/RimLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Toggle(_ENABLE_RIM)]_EnableRim("Enable Rim",Float) = 0
        
        [HDR]_RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimIntensity("Rim Intensity",float) = 1
        _EdgePower("Edge Power",float) = 1
        _EdgeSoft("Edge Soft",Range(0,1)) = 0.5
        
        [Header(Mask)]
        [Toggle(_ENABLE_MASK)]_EnableMask("Enable Mask",Float) = 0
        _RimTex ("Rim Light Texture", 2D) = "white" {}
        _RimMaskIntensity("Rim Mask Intensity",Range(0,1)) = 0.5
        _EdgeMaskPower("Edge Mask Power",Range(0,1)) = 0.5
        

        
        [Header(Flash)]
        [Toggle(_ENABLE_FLASH)]_EnableFlash("Enable Flash",Float) = 0
        _RimSpeed("Rim Speed",float) = 1
        _RimFlashRange("Rim Flash Range",Range(0,1)) = 0.5
        
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
            #pragma shader_feature _ENABLE_RIM
            #pragma shader_feature _ENABLE_MASK
            #pragma shader_feature _ENABLE_FLASH
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            
            half _EdgePower;
            half _EdgeSoft;
            half _EdgeMaskPower;
            sampler2D _RimTex;
            float4 _RimTex_ST;
            half _RimSpeed;
            half _RimFlashRange;
            half _RimIntensity;
            half _RimMaskIntensity;
            half4 _RimColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.objectPos = v.vertex;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 oriCol = tex2D(_MainTex,TRANSFORM_TEX(i.uv, _MainTex));
                // 根据_ENABLE_RIM关键字进行分支，只有开启了_ENABLE_RIM关键字的材质才会执行以下代码
                #if _ENABLE_RIM
                float3 v = UnityWorldSpaceViewDir(i.worldPos);
                float3 n = i.normal;
                // 计算法线点乘视线
                // 使用saturate限定结果在0到1之内
                // 使用normalize将向量归一化
                float d = saturate(dot(normalize(n),normalize(v)));
                // 使用指数运算控制边缘的软硬程度
                d = pow(d,_EdgePower);
                // 控制在0.5附近的过渡强度
                d = smoothstep(0.5-_EdgeSoft,0.5+_EdgeSoft,d);
                d = 1 - d;

                half rimLightIntensity = _RimIntensity;

                // 根据_ENABLE_FLASH关键字进行分支，只有开启了_ENABLE_FLASH关键字的材质才会执行以下代码
                #if _ENABLE_FLASH
                // 控制闪烁
                half t = 0.5*(sin(_Time.y * _RimSpeed)+1);
                rimLightIntensity = lerp(1 - _RimFlashRange,1,t) * _RimIntensity;
                d *= rimLightIntensity;
                # endif

                #if _ENABLE_MASK
                //遮罩
                half rimMask = tex2D(_RimTex,TRANSFORM_TEX(i.uv, _RimTex));
                rimMask = lerp(rimMask,1,1 - _RimMaskIntensity);
                d *= lerp(rimMask,1,d*_EdgeMaskPower);
                #endif
                
                half4 rimCol = d * _RimColor;
                half4 col = rimCol * d + oriCol * (1-d);
                return col;
                
                #else
                return oriCol;
                #endif
                
            }
            ENDCG
        }
    }
}
