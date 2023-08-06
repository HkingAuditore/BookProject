// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter5/UseBRDF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
        _Metallic("_Metallic",Range(0,1)) = 0
        
        [Hearder(Specular)]
        _Shininess("Shininess",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ SHADOWS_SCREEN
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
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
            	SHADOW_COORDS(4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _MainColor;

            half _Shininess;
            half _Metallic;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.objectPos = v.vertex;
            	TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

            	fixed shadow = SHADOW_ATTENUATION(i);

                // 使用Unity中定义的储存光的结构UnityLight传递光照信息
                UnityLight light;
				light.color = _LightColor0.rgb * shadow;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);
                // 使用Unity中定义的储存光的结构UnityIndirect传递间接光照信息
                UnityIndirect indirectLight;
				indirectLight.diffuse = 0.3;
				indirectLight.specular = 0;
                
                // 漫反射
                half4 albedo = tex2D(_MainTex,i.uv) * _MainColor;
                half3 specularColor; 
				float oneMinusReflectivity; 
				albedo.rgb = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularColor, oneMinusReflectivity
				);

                // 反射
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
            	
                // 环境光 + 漫反射 + 高光
                return UNITY_BRDF_PBS(
					albedo, specularColor,
					oneMinusReflectivity, _Shininess,
					normal, viewDir,
					light,indirectLight
				);              
            }
            ENDCG
        }
        
        Pass {
			Tags {
				// 告诉Unity，这个Pass是用来制造阴影的
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			struct appdata {
				float4 position : POSITION;
            	float3 normal : NORMAL;
			};
			float4 vert(appdata v) : SV_POSITION {
				float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
				return UnityApplyLinearShadowBias(position);
			}
			half4 frag () : SV_TARGET {
				return 0;
			}
			
			ENDCG
        }
    }
}
