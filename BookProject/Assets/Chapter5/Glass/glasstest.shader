Shader "Unlit/glasstest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Main Color",color)=(1,1,1,1)
        [Toggle(_INVERT_NORMAL_Y)]_INVERT_NORMAL_Y("Invert normal Y",Float) = 0
        _NormalMap("NormalMap",2D)="bump"{}
        _NormalMapIntensity("NormalMapIntensity",range(0,1))=1
        _RefractionIntensity("RefractionIntensity",range(1,10))=1
        _Thickness("Thickness",range(0,20))=1
        _BlurRadius("BlurRadius",range(0,3))=1
        _BlurScale("BlurScale",range(0,5))=1
        _Smoothness("Smoothness",range(0,1))=0
        _Fresnel("Fresnel",range(0,10))=1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
        }
        GrabPass {}
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ _INVERT_NORMAL_Y
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
                // 获取切线
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
                // 存储切线
                float4 tangent: TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            //获取 GrabPass 抓取的结果
            sampler2D _GrabTexture;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalMapIntensity;
            float _RefractionIntensity;
            half _Thickness;
            float _BlurRadius;
            float _BlurScale;
            float4 _GrabTexture_TexelSize;
            float _Smoothness;
            float4 _MainColor;
            float _Fresnel;


            half3 GetNormalMap(float3 normal, float4 tangent, float2 uv, float intensity, bool invertY)
            {
                // 计算副切线
                float3 bitangent = cross(normal, tangent) * tangent.w;
                float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, uv.xy), intensity);
                float3 newNormal = normalize(
                    normalMap.x * tangent +
                    normalMap.y * (invertY ? -1 : 1) * bitangent +
                    normalMap.z * normal);
                return newNormal;
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                // 切线转换至世界空间
                o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.objectPos = v.vertex;
                return o;
            }

            //对给定 UV 进行采样， x 、 y 表示偏移量
            half3 sample(float2 uv, half x, half y)
            {
                //_GrabTexture_TexelSize 表示 GrabTexture 中一个像素的尺寸 ，四个分量为 1/ 宽、1/ 高、宽、高）
                //1/宽高表示在uv中的距离
                return tex2D(_GrabTexture, uv + _GrabTexture_TexelSize.xy * half2(x, y)).rgb;
            }

            half3 blur(float2 uv)
            {
                //采样原色
                half3 col = sample(uv, 0, 0);
                int sampleCount = 1;
                // _BlurRadius 决定模糊的范围，即对目标像素求外围多少范围像素的均值
                for (int i = 1; i < _BlurRadius; i++)
                {
                    // _BlurScale 决定采样的间隔距离
                    float range = i * _BlurScale;
                    //对八方向进行采样
                    col += sample(uv, range, 0);
                    col += sample(uv, range, 0);
                    col += sample(uv, 0, range);
                    col += sample(uv, 0, range);
                    col += sample(uv, range, range);
                    col += sample(uv, range, range);
                    col += sample(uv, range, range);
                    col += sample(uv, range, range);
                    sampleCount += 8;
                }
                return col / sampleCount;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                #if _INVERT_NORMAL_Y
                float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,true);
                #else
                float3 normal = GetNormalMap(i.normal, i.tangent, i.uv, _NormalMapIntensity, false);
                #endif
                // return half4(normal,1);

                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                half3 refraction = refract(-viewDir, normal, 1 / _RefractionIntensity);
                half thickness = dot(viewDir, normal) * _Thickness;
                float3 refractOutPos = i.worldPos + refraction / dot(refraction, -normal) * thickness;
                float3 oriOutPos = i.worldPos + -viewDir / (-viewDir, -normal) * thickness;
                float4 refractTargetClipPos = mul(UNITY_MATRIX_VP, float4(refractOutPos, 1.0));
                float3 refractTargetNDC = refractTargetClipPos / refractTargetClipPos.w;
                float4 refractOriClipPos = mul(UNITY_MATRIX_VP, float4(oriOutPos, 1.0));
                float3 refractOriNDC = refractOriClipPos / refractOriClipPos.w;
                float3 outOffset = refractTargetNDC - refractOriNDC;
                float3 viewDirNDC = float3(0, 0, 1);
                float2 offset = outOffset + dot(outOffset, -viewDirNDC) * viewDirNDC;
                float2 grabUV = (refractOriNDC + offset) * 0.5 + 0.5;
                #if UNITY_UV_STARTS_AT_TOP
                grabUV.y = 1.0 - grabUV.y;
                #endif
                //反射
                half3 reflection = reflect(-viewDir, normal);
                //采样反射球，第三个参数表示粗糙度，值越小颜色越清晰
                half4 reflectionProbe = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, (1 -_Smoothness)*5);
                // 使用 DecodeHDR 解码 HDR 光照信息
                half3 reflectionColor = DecodeHDR(reflectionProbe, unity_SpecCube0_HDR);
                //菲涅尔
                float fresnel = saturate(pow(saturate(dot(normal, viewDir)), _Fresnel));
                // 折射
                half3 grabColor = blur(grabUV);
                //越靠近边缘，菲涅尔效应越明显
                return half4(lerp(reflectionColor, lerp(grabColor, _MainColor.rgb, _MainColor.a), fresnel), 1);
                //return half4(col.rgb, 1);
                return half4(reflectionColor, 1);
            }
            ENDCG
        }
    }
}