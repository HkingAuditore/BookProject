Shader "Chapter6/Wave"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _TessellationEdge ("Tessellation Edge", Range(1, 64)) = 1
        _TessellationInside("Tessellation Inside", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", Range(0.001, 1)) = 0.5
        
        [Header(wave)]
        _Steepness0("Steepness 0", Range(0, 1)) = 0.5
        _Wavelength0("Wave Length 0", Range(0, 64)) = 1
        _WaveDir0("Wave Direction 0", Vector) = (1,0,0,0)
        _Steepness1("Steepness 1", Range(0, 1)) = 0.5
        _Wavelength1("Wave Length 1", Range(0, 64)) = 1
        _WaveDir1("Wave Direction 1", Vector) = (1,0,0,0)
        
        [Header(Shading)]
        _Metallic("_Metallic",Range(0,1)) = 0
        _Shininess("Shininess",Range(0,1)) = 0.5

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            Cull off
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain doma

            #include "UnityCG.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"


            struct pdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 color : COLOR;
            };
            
            
            struct tessFactor {
                float edgeTess[3] : SV_TessFactor;
                float insideTess : SV_InsideTessFactor;
            };

            struct d2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
                float4 color : TEXCOORD4;
                SHADOW_COORDS(5)
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _TessellationUniform;
            float _TessellationEdgeLength;
            half4 _Color;
            half _TessellationEdge;
            half _TessellationInside;

            half _Steepness0;
            half _Wavelength0;
            half2 _WaveDir0;
            half _Steepness1;
            half _Wavelength1;
            half2 _WaveDir1;

            half _Shininess;
            half _Metallic;

            float3 SampleTrace(float3 p, half2 waveDir, half wavelength, half steepness)
            {
                float lambda =2*UNITY_PI/wavelength;
                float a = wavelength/(2*UNITY_PI)*steepness;
                float v = sqrt((9.8*wavelength)/(2*UNITY_PI));
                half dir = dot(normalize(waveDir),p.xz);
                float y = p.y + a * sin(lambda*(dir-v*_Time.y));
                float x = p.x + normalize(waveDir).x * a * cos(lambda*(dir-v*_Time.y));
                float z = p.z + normalize(waveDir).y * a * cos(lambda*(dir-v*_Time.y));
                return float3(x,y,z);
            }
            float3 MakeWave(float3 p)
            {
                p = SampleTrace(p,_WaveDir0,_Wavelength0,_Steepness0);
                p = SampleTrace(p,_WaveDir1,_Wavelength1,_Steepness1);
                return p;
            }

            pdata vert (pdata v)
            {
                pdata o;
                o.pos = v.pos;
                o.uv = v.uv;
                o.normal = v.normal;
                
                return o;
            }
            

            float TessellationEdgeFactor (pdata cp0, pdata cp1) {
                float3 p0 = mul(unity_ObjectToWorld, float4(cp0.pos.xyz, 1)).xyz;
		        float3 p1 = mul(unity_ObjectToWorld, float4(cp1.pos.xyz, 1)).xyz;
		        float edgeLength = distance(p0, p1);
          
		        float3 edgeCenter = (p0 + p1) * 0.5;
		        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);
          
		        return edgeLength / (_TessellationEdgeLength * pow(viewDistance,2)*0.01);
            }

            tessFactor PatchFunc (InputPatch<pdata, 3> patch){
	            tessFactor f;
                f.edgeTess[0] = TessellationEdgeFactor(patch[1], patch[2]);
                f.edgeTess[1] = TessellationEdgeFactor(patch[2], patch[0]);
                f.edgeTess[2] = TessellationEdgeFactor(patch[0], patch[1]);
	            f.insideTess  = (f.edgeTess[0] + f.edgeTess[1] + f.edgeTess[2]) * (1 / 3.0);
	            return f;
            }

            // tessFactor PatchFunc (InputPatch<pdata, 3> patch){
	           //  tessFactor f;
            //     f.edgeTess[0] = _TessellationEdge;
            //     f.edgeTess[1] = _TessellationEdge;
            //     f.edgeTess[2] = _TessellationEdge;
	           //  f.insideTess  = _TessellationInside;
	           //  return f;
            // }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_patchconstantfunc("PatchFunc")]
            pdata hull(InputPatch<pdata, 3> patch,uint id : SV_OutputControlPointID) {
                pdata o;
                o.pos = patch[id].pos;
                o.uv = patch[id].uv;
                o.normal = patch[id].normal;
                o.color = (step(-0.1,id)-step(0.1,id))*half4(1,0,0,0)
                          +(step(0.9,id)-step(1.1,id))*half4(0,1,0,0)
                          +(step(1.9,id)-step(2.1,id))*half4(0,0,1,0);
	            return o;
            }

            

            float3 CalculateNormal(float dhx, float dhz, float scale)
            {
	            float3 tx = normalize(float3(scale, dhx, 0));
	            float3 tz = normalize(float3(0, dhz, scale));

	            float3 normal = cross(tz, tx);
	            return normalize(normal);
            }
            
            #define DOMAIN_INTERPOLATE(field) o.field =\
                patch[0].field * bary.x + \
                patch[1].field * bary.y + \
                patch[2].field * bary.z;
            [UNITY_domain("tri")]
            d2f doma (tessFactor i, OutputPatch<pdata, 3> patch, float3 bary : SV_DomainLocation)
            {
                d2f o;
                DOMAIN_INTERPOLATE(pos)
                DOMAIN_INTERPOLATE(color)
                DOMAIN_INTERPOLATE(normal)
                DOMAIN_INTERPOLATE(uv)
                

                half scale = 0.1;
                float3 p1=MakeWave(o.pos+scale * float3(1,0,0));
                float3 p2=MakeWave(o.pos+scale * float3(0,0,-1));
                o.objectPos = o.pos;
                o.objectPos.xyz = MakeWave(o.objectPos.xyz);
                o.pos = UnityObjectToClipPos(o.objectPos);
                o.worldPos = mul(unity_ObjectToWorld,o.objectPos);
                o.normal = UnityObjectToWorldNormal(normalize(
                    CalculateNormal(p1.y-o.objectPos.y,p2.y-o.objectPos.y,scale)
                ));
                TRANSFER_SHADOW(o)
                return o;
            }
            

            fixed4 frag (d2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half shadow = SHADOW_ATTENUATION(i);
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
                half4 albedo = tex2D(_MainTex,i.uv) * _Color;
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
            #pragma hull hull
            #pragma domain doma
			
			#include "UnityCG.cginc"
			struct pdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 color : COLOR;
            };
            
            
            struct tessFactor {
                float edgeTess[3] : SV_TessFactor;
                float insideTess : SV_InsideTessFactor;
            };

            struct d2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float4 objectPos : TEXCOORD3;
                float4 color : TEXCOORD4;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _TessellationUniform;
            float _TessellationEdgeLength;
            half4 _Color;
            half _TessellationEdge;
            half _TessellationInside;

            half _Steepness0;
            half _Wavelength0;
            half2 _WaveDir0;
            half _Steepness1;
            half _Wavelength1;
            half2 _WaveDir1;

            half _Shininess;
            half _Metallic;

            float3 SampleTrace(float3 p, half2 waveDir, half wavelength, half steepness)
            {
                float lambda =2*UNITY_PI/wavelength;
                float a = wavelength/(2*UNITY_PI)*steepness;
                float v = sqrt((9.8*wavelength)/(2*UNITY_PI));
                half dir = dot(normalize(waveDir),p.xz);
                float y = p.y + a * sin(lambda*(dir-v*_Time.y));
                float x = p.x + normalize(waveDir).x * a * cos(lambda*(dir-v*_Time.y));
                float z = p.z + normalize(waveDir).y * a * cos(lambda*(dir-v*_Time.y));
                return float3(x,y,z);
            }
            float3 MakeWave(float3 p)
            {
                p = SampleTrace(p,_WaveDir0,_Wavelength0,_Steepness0);
                p = SampleTrace(p,_WaveDir1,_Wavelength1,_Steepness1);
                return p;
            }

            pdata vert (pdata v)
            {
                pdata o;
                o.pos = v.pos;
                o.uv = v.uv;
                o.normal = v.normal;
                
                return o;
            }
            

            float TessellationEdgeFactor (pdata cp0, pdata cp1) {
                float3 p0 = mul(unity_ObjectToWorld, float4(cp0.pos.xyz, 1)).xyz;
		        float3 p1 = mul(unity_ObjectToWorld, float4(cp1.pos.xyz, 1)).xyz;
		        float edgeLength = distance(p0, p1);

		        float3 edgeCenter = (p0 + p1) * 0.5;
		        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

		        return edgeLength / (_TessellationEdgeLength * pow(viewDistance,2)*0.01);
            }

            tessFactor PatchFunc (InputPatch<pdata, 3> patch){
	            tessFactor f;
                f.edgeTess[0] = TessellationEdgeFactor(patch[1], patch[2]);
                f.edgeTess[1] = TessellationEdgeFactor(patch[2], patch[0]);
                f.edgeTess[2] = TessellationEdgeFactor(patch[0], patch[1]);
	            f.insideTess  = (f.edgeTess[0] + f.edgeTess[1] + f.edgeTess[2]) * (1 / 3.0);
	            return f;
            }



            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_patchconstantfunc("PatchFunc")]
            pdata hull(InputPatch<pdata, 3> patch,uint id : SV_OutputControlPointID) {
                pdata o;
                o.pos = patch[id].pos;
                o.uv = patch[id].uv;
                o.normal = patch[id].normal;
                o.color = (step(-0.1,id)-step(0.1,id))*half4(1,0,0,0)
                          +(step(0.9,id)-step(1.1,id))*half4(0,1,0,0)
                          +(step(1.9,id)-step(2.1,id))*half4(0,0,1,0);
	            return o;
            }

            

            float3 CalculateNormal(float dhx, float dhz, float scale)
            {
	            float3 tx = normalize(float3(scale, dhx, 0));
	            float3 tz = normalize(float3(0, dhz, scale));

	            float3 normal = cross(tz, tx);
	            return normalize(normal);
            }
            
            #define DOMAIN_INTERPOLATE(field) o.field =\
                patch[0].field * bary.x + \
                patch[1].field * bary.y + \
                patch[2].field * bary.z;
            [UNITY_domain("tri")]
            d2f doma (tessFactor i, OutputPatch<pdata, 3> patch, float3 bary : SV_DomainLocation)
            {
                d2f o;
                DOMAIN_INTERPOLATE(pos)
                DOMAIN_INTERPOLATE(color)
                DOMAIN_INTERPOLATE(normal)
                DOMAIN_INTERPOLATE(uv)
                

                half scale = 1;
                float3 p1=MakeWave(o.pos+scale * float3(1,0,0));
                float3 p2=MakeWave(o.pos+scale * float3(0,0,-1));
                o.objectPos = o.pos;
                o.objectPos.xyz = MakeWave(o.objectPos.xyz);
                o.pos = UnityObjectToClipPos(o.objectPos);
                o.worldPos = mul(unity_ObjectToWorld,o.objectPos);
                o.normal = UnityObjectToWorldNormal(normalize(
                    CalculateNormal(p1.y-o.objectPos.y,p2.y-o.objectPos.y,scale)
                ));
                return o;
            }

			half4 frag () : SV_TARGET {
				return 0;
			}
			
			ENDCG
        }
    }
}
