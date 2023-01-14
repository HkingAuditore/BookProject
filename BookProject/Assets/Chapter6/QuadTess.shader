Shader "Unlit/QuadTess"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _TessellationUniform ("Tessellation Uniform", Range(1, 64)) = 1
        _TessellationEdgeLength ("Tessellation Edge Length", Range(0.001, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
//            Cull off
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile_fwdadd_fullshadows
            #pragma vertex vert
            #pragma fragment frag
            #pragma hull hull
            #pragma domain doma

            #include "UnityCG.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2h
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD2;
            };
            
            struct h2t
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD2;
                float4 color : COLOR;
            };
            
            // struct tessFactor {
            //     float edgeTess[4] : SV_TessFactor;
            //     float insideTess[2] : SV_InsideTessFactor;
            // };
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

            float3 MakeWave(float3 p)
            {
                // return float3(p.x,
                //               ((smoothstep(-1,1,sin(_Time.y*10))*0.05+0.2)*sin(_Time.y*0.0008*p.x*1.5)+(smoothstep(-1,1,sin(5*_Time.y+5))*0.25+0.25)*cos(_Time.y*0.0012*(p.z+8)*2)),
                //               p.z);
                return float3(p.x,0.25*(sin(_Time.y+p.x*2)+cos(_Time.y+p.z*2)),p.z);
            }

            v2h vert (appdata v)
            {
                v2h o;
                o.pos = v.vertex;
                o.uv = v.uv;
                o.normal = v.normal;
                
                return o;
            }
            

            float TessellationEdgeFactor (v2h cp0, v2h cp1) {
	         //    float3 p0 = mul(unity_ObjectToWorld, float4(cp0.pos.xyz, 1)).xyz;
		        // float3 p1 = mul(unity_ObjectToWorld, float4(cp1.pos.xyz, 1)).xyz;
		        // float edgeLength = distance(p0, p1);
		        // return edgeLength / _TessellationEdgeLength;
                float3 p0 = mul(unity_ObjectToWorld, float4(cp0.pos.xyz, 1)).xyz;
		        float3 p1 = mul(unity_ObjectToWorld, float4(cp1.pos.xyz, 1)).xyz;
		        float edgeLength = distance(p0, p1);

		        float3 edgeCenter = (p0 + p1) * 0.5;
		        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

		        return edgeLength / (_TessellationEdgeLength * pow(viewDistance,2)*0.01);
            }

            // tessFactor PatchFunc (InputPatch<v2h, 3> patch){
	           //  tessFactor f;
            //     f.edgeTess[0] = TessellationEdgeFactor(patch[1], patch[2]);
            //     f.edgeTess[1] = TessellationEdgeFactor(patch[2], patch[0]);
            //     f.edgeTess[2] = TessellationEdgeFactor(patch[0], patch[1]);
	           //  f.insideTess  = (f.edgeTess[0] + f.edgeTess[1] + f.edgeTess[2]) * (1 / 3.0);
	           //  return f;
            // }

            // tessFactor PatchFunc (InputPatch<v2h, 4> patch){
	           //  tessFactor f;
            //     f.edgeTess[0] = 2;
            //     f.edgeTess[1] = 2;
            //     f.edgeTess[2] = 2;
            //     f.edgeTess[3] = 2;
	           //  f.insideTess[0]  = 2;
	           //  f.insideTess[1]  = 2;
	           //  return f;
            // }
            tessFactor PatchFunc (InputPatch<v2h, 3> patch){
	            tessFactor f;
                f.edgeTess[0] = 1;
                f.edgeTess[1] = 1;
                f.edgeTess[2] = 1;
	            f.insideTess  = 3;
	            return f;
            }

			// [UNITY_domain("quad")]
			// [UNITY_outputcontrolpoints(4)]
			// [UNITY_outputtopology("triangle_cw")]
			// [UNITY_partitioning("fractional_odd")]
   //          [UNITY_patchconstantfunc("PatchFunc")]
   //          h2t hull(InputPatch<v2h, 4> patch,uint id : SV_OutputControlPointID) {
   //              h2t o;
   //              o.pos = patch[id].pos;
   //              o.uv = patch[id].uv;
   //              o.normal = patch[id].normal;
   //              o.color = (step(-0.1,id)-step(0.1,id))*half4(1,0,0,0)
   //                        +(step(0.9,id)-step(1.1,id))*half4(0,1,0,0)
   //                        +(step(1.9,id)-step(2.1,id))*half4(0,0,1,0);
	  //           return o;
   //          }
            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_partitioning("integer")]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_patchconstantfunc("PatchFunc")]
            h2t hull(InputPatch<v2h, 3> patch,uint id : SV_OutputControlPointID) {
                h2t o;
                o.pos = patch[id].pos;
                o.uv = patch[id].uv;
                o.normal = patch[id].normal;
                o.color = (step(-0.1,id)-step(0.1,id))*half4(1,0,0,0)
                          +(step(0.9,id)-step(1.1,id))*half4(0,1,0,0)
                          +(step(1.9,id)-step(2.1,id))*half4(0,0,1,0);
	            return o;
            }

            #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) d.fieldName = \
		    patch[0].fieldName * bary.x + \
		    patch[1].fieldName * bary.y + \
		    patch[2].fieldName * bary.z;

            float3 CalculateNormal(float dhx, float dhz, float scale)
            {
	            float3 tx = float3(scale, dhx, 0);
	            float3 tz = float3(0, dhz, scale);

	            float3 normal = cross(tz, tx);
                // return dhx*dhz;
	            return normalize(normal);
            }

       //      [UNITY_domain("quad")]
       //      d2f doma (tessFactor i,  OutputPatch<h2t, 4> patch, float2 bary : SV_DomainLocation)
       //      {
       //
       //          d2f o;
       //      	float3 v1 = lerp(patch[0].pos, patch[1].pos, bary.x);
			    // float3 v2 = lerp(patch[2].pos, patch[3].pos, bary.x);
			    // float3 p = lerp(v1, v2, bary.y); 
       //          o.objectPos = half4(p,1);
       //          o.pos = UnityObjectToClipPos(o.objectPos);
       //          o.uv = lerp(lerp(patch[0].uv, patch[1].uv, bary.x), lerp(patch[2].uv, patch[3].uv, bary.x), bary.y); 
       //          o.color = lerp(lerp(patch[0].color, patch[1].color, bary.x), lerp(patch[2].color, patch[3].color, bary.x), bary.y); 
       //          o.worldPos = mul(unity_ObjectToWorld,o.objectPos);
       //          o.normal = UnityObjectToWorldNormal(normalize(lerp(lerp(patch[0].normal, patch[1].normal, bary.x), lerp(patch[2].normal, patch[3].normal, bary.x), bary.y)));
       //          
       //          return o;
       //      }
            [UNITY_domain("tri")]
            d2f doma (tessFactor i, OutputPatch<h2t, 3> patch, float3 bary : SV_DomainLocation)
            {
            
                d2f o;
                o.objectPos = patch[0].pos * bary.x +patch[1].pos * bary.y + patch[2].pos * bary.z;
                o.pos = UnityObjectToClipPos(o.objectPos);
                o.uv = patch[0].uv * bary.x +patch[1].uv * bary.y + patch[2].uv * bary.z;
                o.color = patch[0].color * bary.x +patch[1].color * bary.y + patch[2].color * bary.z;
                o.worldPos = mul(unity_ObjectToWorld,o.objectPos);
                o.normal = UnityObjectToWorldNormal(normalize(patch[0].normal * bary.x +patch[1].normal * bary.y + patch[2].normal * bary.z));
                
                return o;
            }
            // [UNITY_domain("tri")]
            // t2f doma (tessFactor i, OutputPatch<h2t, 3> patch, float3 bary : SV_DomainLocation)
            // {
            //     h2t d;
            //     MY_DOMAIN_PROGRAM_INTERPOLATE(pos)
	           //  MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	           //  MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
	           //  MY_DOMAIN_PROGRAM_INTERPOLATE(color)
            //     
            //     t2f o;
            //     half scale = 1;
            //     float3 p0=MakeWave(d.pos.xyz);
            //     float3 p1=MakeWave(d.pos+scale * float3(-1,0,0));
            //     float3 p2=MakeWave(d.pos+scale * float3(1,0,0));
            //     float3 p3=MakeWave(d.pos+scale * float3(0,0,-1));
            //     float3 p4=MakeWave(d.pos+scale * float3(0,0,1));
            //     // o.objectPos = float4(p0,1);
            //     o.objectPos = d.pos;
            //     o.pos = UnityObjectToClipPos(o.objectPos);
            //     o.uv = d.uv;
            //     o.color = d.color;
            //     o.worldPos = mul(unity_ObjectToWorld,o.objectPos);
            //     
            //     o.normal = UnityObjectToWorldNormal(normalize(
            //         CalculateNormal(p2.y-p1.y,p4.y-p3.y,scale)
            //     ));
            //     // o.normal = UnityObjectToWorldNormal(
            //     //     float3(p2.y-p1.y,p4.y-p3.y,0)
            //     // );
            //     
            //     return o;
            // }

            fixed4 frag (d2f i) : SV_Target
            {
                float3 l = normalize(_WorldSpaceLightPos0.xyz);
                float3 n = normalize(i.normal);
                
                float3 ambient = ShadeSH9(float4(n, 1)) * _Color.rgb;
                half3 diffuse = dot(n,l) * _Color.rgb;
                return 1;
                return float4(i.color.rgb,1);
            }
            ENDCG
        }
    }
}
