Shader "Chapter5/Glass"
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
    	
		_RefractionIntensity ("Refraction Intensity", Range(-10,10)) = 0
        _Thickness("Thickness", Range(0,20)) = 0
    	
		_Fresnel ("Fresnel", Range(0,10)) = 1
    	
		_BlurRadius ("Blur Radius", Range(0,100)) = 1
		_BlurScale ("Blur Scale", Range(0,3)) = 1

    }
    SubShader
    {
        Tags {
             "Queue"="Transparent"
        }
        
    	
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
            #pragma multi_compile_fwdadd_fullshadows
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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
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


            half3 sample(float2 uv,half x,half y)
            {
	            return tex2D( _GrabTexture, uv+_GrabTexture_TexelSize*half2(x,y)).rgb;
            }

            half weight(half x, half y, half sigma)
            {
				return (1/sqrt(2*UNITY_PI))*exp(-(x*x+y*y)/(2*sigma*sigma));    
            }
            
            half3 blur(float2 uv)
            {
				half3 col = sample(uv,0, 0);

            	int sampleCount = 1;
            	// half weightSum =  weight(0, 0, 1);
				for (int i = 1; i <= _BlurRadius; i++)
				{
					float range = i * _BlurScale;
					col += sample(uv,range, 0)      ;
					col += sample(uv,-range, 0)     ;
					col += sample(uv,0, range)      ;
					col += sample(uv,0, -range)     ;
					col += sample(uv,range, range  );
					col += sample(uv,range, -range );
					col += sample(uv,-range, range );
					col += sample(uv,-range, -range);
					// weightSum += weight(range, 0, 1);
					// weightSum += weight(-range, 0, 1);
					// weightSum += weight(0, range, 1);
					// weightSum += weight(0, -range, 1);
					// weightSum += weight(range, range  , 1);
					// weightSum += weight(range, -range , 1);
					// weightSum += weight(-range, range , 1);
					// weightSum += weight(-range, -range, 1);
					sampleCount += 8;
				}
            	return col / sampleCount;
            }


            fixed4 frag (v2f i) : SV_Target
            {
            	#if _INVERT_NORMAL_Y
				float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,true);
            	#else
            	float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,false);
            	#endif
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
            	float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

            	// 用菲涅尔模拟厚度，以边缘处为薄
            	half thickness = dot(viewDir,normal) * _Thickness;
            	// 折射方向
            	half3 refraction = refract(-viewDir,normal,1/_RefractionIntensity);
            	float4 refractTargetClipPos = mul(UNITY_MATRIX_VP, float4(i.worldPos + refraction/dot(refraction,-normal) * thickness, 1.0));
            	float3 refractTargetNDC = refractTargetClipPos / refractTargetClipPos.w;
            	float4 refractOriClipPos = mul(UNITY_MATRIX_VP, float4(i.worldPos + -viewDir/dot(-viewDir,-normal) * thickness, 1.0));
            	float3 refractOriNDC = refractOriClipPos / refractOriClipPos.w;
            	// 计算折射造成的视线偏移
            	float3 outOffset = refractTargetNDC - refractOriNDC;
            	// 对outOffset做投影
            	float3 cameraDirNDC = float3(0,0,1);
            	float2 offset = outOffset+dot(outOffset,-cameraDirNDC)*cameraDirNDC;
            	float2 grabUV = (refractOriNDC + offset) * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
				grabUV.y = 1.0 - grabUV .y;
				#endif
            	
            	// 采样画面
            	float3 grab = blur(grabUV);
            	// return half4(grab,1);

            	// shadow
            	fixed shadow = SHADOW_ATTENUATION(i);

            	// 菲涅尔
            	float fresnel = pow(saturate(dot(normal,viewDir)),_Fresnel);

                // 反射
            	half3 reflection = reflect(-viewDir, normal);
            	half4 reflectionProbe = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflection, (1-_Smoothness)*5); 
				half3 reflectionColor = DecodeHDR (reflectionProbe, unity_SpecCube0_HDR);

            	// 环境光
            	float3 shLighting = ShadeSH9(float4(normal, 1));
                
                // 漫反射
                half4 albedo = tex2D(_MainTex,i.uv) * _MainColor;
                half3 specularColor; 
				float invertReflectivity;   
				albedo.rgb = DiffuseAndSpecularFromMetallic(
					albedo.rgb, _Metallic, specularColor, invertReflectivity
				);
                albedo.rgb *= 1- _Metallic;
                half diffuse = saturate(dot(normal,lightDir));
				half3 diffuseFinal = diffuse * albedo * _LightColor0.rgb * shadow;
                
            	
                half3 ambient = (shLighting) * albedo * albedo.a * shadow;

                // 高光反射
                float3 halfVector = normalize(lightDir+viewDir);
                half specular = pow(max(0,dot(normal, halfVector)), _Smoothness*500);
            	// 用阴影约束光强
                half3 specularFinal = specular * specularColor * _LightColor0.rgb * shadow;

            	//通过菲涅尔确定反射和折射光线的比例
                return half4(lerp(lerp(grab,diffuseFinal,albedo.a) + specularFinal + ambient,reflectionColor,1-fresnel) , 1);                

            }
            ENDCG
        }
    	
    	Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile _ _ENABLE_CUTOFF
			
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			struct appdata {
				float4 position : POSITION;
            	float3 normal : NORMAL;
            	float2 uv : TEXCOORD0;
			};

			struct v2f
            {
				#ifdef _ENABLE_CUTOFF
                float2 uv : TEXCOORD0;
				#endif
                float4 position : SV_POSITION;
            };

			sampler2D _MainTex;
            float4 _MainTex_ST;
			half _Cutoff;
			
			v2f vert(appdata v) {
				v2f o;
				o.position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
				#ifdef _ENABLE_CUTOFF
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				#endif
				return o;
			}
			half4 frag (v2f i) : SV_Target {
				#ifdef _ENABLE_CUTOFF
				clip(tex2D(_MainTex,i.uv).a - _Cutoff);
				#endif
				return 0;
			}
			
			ENDCG
        }

    }
}
