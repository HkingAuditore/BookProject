Shader "Unlit/GlassExample"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _Metallic("_Metallic",Range(0,1)) = 0
        
        [Header(Specular)]
        _Smoothness("_Smoothness",Range(0.01,1)) = 0.5
    	
    	[Header(Normal Map)]
    	_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapIntensity ("Normal Map Intensity", Float) = 1
    	[Toggle(_INVERT_NORMAL_Y)]_INVERT_NORMAL_Y("Invert Normal Y Axis",Float) = 0
    	
		_RefractionIntensity ("Refraction Intensity", Range(1,10)) = 0
        _Thickness("Thickness", Range(0,5)) = 0
    	
		_Fresnel ("Fresnel", Range(0,10)) = 1
    	
		_BlurRadius ("Blur Radius", Range(0,100)) = 1
		_BlurScale ("Blur Scale", Range(0,3)) = 1
    }
    SubShader
    {
        Tags {"Queue"="Transparent"}
        
        GrabPass{ }

        Pass
        {
            Tags{
            	 "LightMode" = "ForwardBase"
            	 "Queue" = "Transparent"
            	}
        	Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ _INVERT_NORMAL_Y
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : COLOR;
            	float4 tangent : TANGENT;
            };
            struct v2f
            {
            	float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            	float4 tangent: TEXCOORD4;
            	SHADOW_COORDS(6)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;



            sampler2D _GrabTexture;
            half2 _GrabTexture_TexelSize;
            
            half4 _MainColor;

            half _Smoothness;
            half _Metallic;
            half _NormalMapIntensity;
            
            half _RefractionIntensity;
			half _Thickness;
            
            half _Fresnel;
            half _BlurRadius;
            half _BlurScale;

            half3 GetNormalMap(float3 normal, float4 tangent, float2 uv, float intensity,bool invertY)
            {
	            float3 bitangent =normalize( cross(normal, tangent) * tangent.w);
            	float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, uv.xy * _NormalMap_ST), intensity);
            	float3 newNormal = normalize(
											normalMap.x * tangent +
											normalMap.y * (invertY?-1:1) * bitangent +
											normalMap.z * normal
									);
            	return newNormal;
            }

            // 对给定UV进行采样，x、y表示偏移量
            half3 sample(float2 uv,half x,half y)
			{
            	//_GrabTexture_TexelSize表示GrabTexture中一个像素的尺寸
			    return tex2D( _GrabTexture, uv+_GrabTexture_TexelSize*half2(x,y)).rgb;
			}
            
			half3 blur(float2 uv)
			{
				half3 col = sample(uv,0, 0);
				int sampleCount = 1;
            	// _BlurRadius决定模糊的范围，即对目标像素求外围多少范围像素的均值
				for (int i = 0; i < _BlurRadius; i++)
				{
					// __BlurScale决定采样的间隔距离
					float range = i*_BlurScale;
					col += sample(uv,range, 0);
					col += sample(uv,-range, 0);
					col += sample(uv,0, range);
					col += sample(uv,0, -range);
					col += sample(uv,range, range);
					col += sample(uv,range, -range);
					col += sample(uv,-range, range);
					col += sample(uv,-range, -range);
					sampleCount += 8;
				}
				return col/sampleCount;
			}



            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.objectPos = v.vertex;
            	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
            	TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
            	// 我们在发现法线贴图章节中实现的GetNormalMap函数
            	#if _INVERT_NORMAL_Y
				float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,true);
            	#else
            	float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,false);
            	#endif
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
            	float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            	
                // 折射方向
            	// 第三个参数为折射率，我们使用1/_RefractionIntensity将[0,1]的属性映射到(0,无穷)
				half3 refraction = refract(-viewDir,normal,1/_RefractionIntensity);
            	// 用菲涅尔模拟厚度，以边缘处为薄
				half thickness = dot(viewDir,normal) * _Thickness;
				float4 refractTargetClipPos = mul(UNITY_MATRIX_VP, float4(i.worldPos + refraction/dot(refraction,-normal) * thickness, 1.0));
				float2 refractTargetNDC = (refractTargetClipPos / refractTargetClipPos.w) * 0.5 + 0.5;
				float4 refractOriClipPos = mul(UNITY_MATRIX_VP, float4(i.worldPos + -viewDir/dot(-viewDir,-normal) * thickness, 1.0));
				float2 refractOriNDC = (refractOriClipPos / refractOriClipPos.w) * 0.5 + 0.5;
				// 计算折射造成的视线偏移
				float2 offset = (refractTargetNDC - refractOriNDC);
            	float2 grabUV = refractTargetNDC + offset;
            	#if UNITY_UV_STARTS_AT_TOP
				grabUV.y = 1.0 - grabUV.y;
				#endif

            	// 反射
				half3 reflection = reflect(-viewDir, normal);
				half4 reflectionProbe = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, (1-_Smoothness)*5); 
				half3 reflectionColor = DecodeHDR (reflectionProbe, unity_SpecCube0_HDR);
            	// 菲涅尔
				float fresnel = pow(saturate(dot(normal,viewDir)),_Fresnel);

                half3 grabColor = blur(grabUV);
            	// 越靠近边缘，菲涅尔效应越明显
                return half4(lerp(reflectionColor,lerp(grabColor,_MainColor.rgb,_MainColor.a),fresnel),1);    
            }
            ENDCG
        }
    }
}
