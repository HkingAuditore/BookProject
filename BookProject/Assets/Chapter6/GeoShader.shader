Shader "Custom/GeoShader"
{
	Properties
	{
		_GroundColor("Ground Color", Color) = (1, 1, 1, 1)
		_GrassTex ("Grass Texture", 2D) = "white" {}
		_GrassCount("Grass per triangle", Range(0,20)) = 20
		_GrassWidth("Grass Width", Range(0,1)) = 0.1
		_GrassCutoff("Grass Cutoff", Range(0,1)) = 0.1
		_GrassTall("Grass Tall", Range(0,1)) = 0.1
	}

	SubShader
	{
		Pass
		{
			Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry" "LightMode" = "ForwardBase"}
			Cull off
			CGPROGRAM
			#pragma target 4.0
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag

			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

			struct appdata {
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			    float4 uv : TEXCOORD0;
			};
			struct v2g {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			struct g2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float4 color : TEXCOORD1;
				float2 uv : TEXCOORD2;
				float3 posObj : TEXCOORD3;
				SHADOW_COORDS(4)
				
				
			};

			int _GrassCount;
			half _GrassWidth;
			sampler2D _GrassTex;
            float4 _GrassTex_ST;
            half4 _GroundColor;
			half _GrassCutoff;
			half _GrassTall;

			v2g vert(appdata v) 
			{
				v2g o;
				o.pos = v.vertex;
				o.normal = v.normal;
				o.uv=v.uv;
				return o;
			}

			g2f CreateG2F(v2g i)
			{
				g2f o;
				o.pos = i.pos;
				o.posObj = i.pos;
				o.normal = UnityObjectToWorldNormal(i.normal);
				o.pos = UnityObjectToClipPos(o.pos);
				o.color = half4(1,0,1,1);
				o.uv=i.uv;

				TRANSFER_SHADOW(o);
				return o;
			}
			g2f CreateG2F(float3 pos, float2 uv, float3 normal, float4 color)
			{
				g2f o;
				o.pos = half4(pos,1);
				o.posObj = pos;
				o.normal = normal;
				o.color = color;
				o.pos = UnityObjectToClipPos(o.pos);
				o.uv=uv;
				TRANSFER_SHADOW(o);
				return o;
			}

			float2 RandomFloat2(float2 uv)
			{
				float vec = dot(uv, float2(127.1, 311.7));
				return half2(-1.0 + 2.0 * frac(sin(vec) * 2345.8768),
							-1.0 + 2.0 * frac(sin(vec) * 4321.1254)
					);
			}
			
			float3 RandomFloat3(float2 uv)
			{
				float vec = dot(uv, float2(127.1, 311.7));
				return half3(-1.0 + 2.0 * frac(sin(vec) * 2345.8768),
							-1.0 + 2.0 * frac(sin(vec) * 4321.1254),
							-1.0 + 2.0 * frac(sin(vec) * 678.298)
					);
			}


			void CreateGrass(float3 center, float3 normal, inout TriangleStream<g2f> stream)
			{
				float2 dir = normalize(RandomFloat2(center.xz));
				float3 p0 = center -  _GrassWidth * float3(dir.x,0,dir.y);
				float3 p1 = center +  _GrassWidth * float3(dir.x,0,dir.y);
				float tall = frac(sin( dot(center.xz, float2(127.1, 311.7))) * 678.298) * 3;
				float3 p2 = center + _GrassTall * normal * tall -  _GrassWidth * float3(dir.x,0,dir.y);
				float3 p3 = center + _GrassTall * normal * tall +  _GrassWidth * float3(dir.x,0,dir.y);
				float3 n = normalize(cross(p1-p0,p2-p0));
				stream.Append(CreateG2F(p0,half2(0,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p1,half2(1,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p2,half2(0,1),n,half4(0,1,0,1)));
				stream.RestartStrip();
				stream.Append(CreateG2F(p1,half2(1,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p3,half2(1,1),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p2,half2(0,1),n,half4(0,1,0,1)));
				stream.RestartStrip();
			}

			// 定义一个名为MAX_VERTEX_COUNT的宏，值为3+6*9
			#define MAX_VERTEX_COUNT 3+6*10
			[maxvertexcount(MAX_VERTEX_COUNT)]
			void geo(triangle  v2g p[3], inout TriangleStream<g2f> stream)
			{
				// 原面
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(p[1]));
				stream.Append(CreateG2F(p[2]));
				stream.RestartStrip();

				// 面法线
				float3 t0 = p[1].pos-p[0].pos;
				float3 t1 = p[2].pos-p[0].pos;
				float3 n = normalize(cross(t0,t1));
				
				float3 center = .33*(p[0].pos.xyz+p[1].pos.xyz+p[2].pos.xyz);
				float3 dirTo0 = normalize(p[0].pos-center);
				float3 dirTo1 = normalize(p[1].pos-center);
				float3 dirTo2 = normalize(p[2].pos-center);
				// 随机插片
				for (int i = 0; i < _GrassCount; i++)
				{
					half3 noise =  .5*normalize(RandomFloat3(center.xz + i));
					float3 grassCenter = center + dirTo0*noise.x + dirTo1*noise.y + dirTo2*noise.z;
					CreateGrass(grassCenter,n,stream);
				}
				
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 l = normalize(_WorldSpaceLightPos0.xyz);
				fixed shadow = SHADOW_ATTENUATION(i);
				half4 grassTex = tex2D(_GrassTex,i.uv);
				half ao = (i.posObj.y + .2) * 2;
				grassTex.rgb *= ao;
				half4 col =lerp(_GroundColor,grassTex,i.color.g);
				clip(col.a-_GrassCutoff);
				half4 nol = abs(dot((i.normal),l)) * shadow * .5 + .5;
				
				return col * nol;
				// return half4(i.normal,1);
				return dot(i.normal,l) * shadow;
			}

			ENDCG
		}
		Pass
		{
			Tags { "LightMode" = "ShadowCaster"}
			Cull off
			CGPROGRAM
			#pragma target 4.0
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag

			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

			struct appdata {
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			    float4 uv : TEXCOORD0;
			};
			struct v2g {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			struct g2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float4 color : TEXCOORD1;
				float2 uv : TEXCOORD2;
				float3 posObj : TEXCOORD3;
				SHADOW_COORDS(4)
				
				
			};

			int _GrassCount;
			half _GrassWidth;
			sampler2D _GrassTex;
            float4 _GrassTex_ST;
            half4 _GroundColor;
			half _GrassCutoff;
			half _GrassTall;

			v2g vert(appdata v) 
			{
				v2g o;
				o.pos = v.vertex;
				o.normal = v.normal;
				o.uv=v.uv;
				return o;
			}

			g2f CreateG2F(v2g i)
			{
				g2f o;
				o.pos = i.pos;
				o.posObj = i.pos;
				o.normal = UnityObjectToWorldNormal(i.normal);
				o.pos = UnityObjectToClipPos(o.pos);
				o.color = half4(1,0,1,1);
				o.uv=i.uv;

				TRANSFER_SHADOW(o);
				return o;
			}
			g2f CreateG2F(float3 pos, float2 uv, float3 normal, float4 color)
			{
				g2f o;
				o.pos = half4(pos,1);
				o.posObj = pos;
				o.normal = normal;
				o.color = color;
				o.pos = UnityObjectToClipPos(o.pos);
				o.uv=uv;
				TRANSFER_SHADOW(o);
				return o;
			}

			float2 RandomFloat2(float2 uv)
			{
				float vec = dot(uv, float2(127.1, 311.7));
				return half2(-1.0 + 2.0 * frac(sin(vec) * 2345.8768),
							-1.0 + 2.0 * frac(sin(vec) * 4321.1254)
					);
			}
			
			float3 RandomFloat3(float2 uv)
			{
				float vec = dot(uv, float2(127.1, 311.7));
				return half3(-1.0 + 2.0 * frac(sin(vec) * 2345.8768),
							-1.0 + 2.0 * frac(sin(vec) * 4321.1254),
							-1.0 + 2.0 * frac(sin(vec) * 678.298)
					);
			}


			void CreateGrass(float3 center, float3 normal, inout TriangleStream<g2f> stream)
			{
				float2 dir = normalize(RandomFloat2(center.xz));
				float3 p0 = center -  _GrassWidth * float3(dir.x,0,dir.y);
				float3 p1 = center +  _GrassWidth * float3(dir.x,0,dir.y);
				float tall = frac(sin( dot(center.xz, float2(127.1, 311.7))) * 678.298) * 3;
				float3 p2 = center + _GrassTall * normal * tall -  _GrassWidth * float3(dir.x,0,dir.y);
				float3 p3 = center + _GrassTall * normal * tall +  _GrassWidth * float3(dir.x,0,dir.y);
				float3 n = normalize(cross(p1-p0,p2-p0));
				stream.Append(CreateG2F(p0,half2(0,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p1,half2(1,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p2,half2(0,1),n,half4(0,1,0,1)));
				stream.RestartStrip();
				stream.Append(CreateG2F(p1,half2(1,0),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p3,half2(1,1),n,half4(0,1,0,1)));
				stream.Append(CreateG2F(p2,half2(0,1),n,half4(0,1,0,1)));
				stream.RestartStrip();
			}

			// 定义一个名为MAX_VERTEX_COUNT的宏，值为3+6*9
			#define MAX_VERTEX_COUNT 3+6*8
			[maxvertexcount(MAX_VERTEX_COUNT)]
			void geo(triangle  v2g p[3], inout TriangleStream<g2f> stream)
			{
				// 原面
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(p[1]));
				stream.Append(CreateG2F(p[2]));
				stream.RestartStrip();

				// 面法线
				float3 t0 = p[1].pos-p[0].pos;
				float3 t1 = p[2].pos-p[0].pos;
				float3 n = normalize(cross(t0,t1));
				
				float3 center = .33*(p[0].pos.xyz+p[1].pos.xyz+p[2].pos.xyz);
				float3 dirTo0 = normalize(p[0].pos-center);
				float3 dirTo1 = normalize(p[1].pos-center);
				float3 dirTo2 = normalize(p[2].pos-center);
				// 随机插片
				for (int i = 0; i < _GrassCount; i++)
				{
					half3 noise =  .5*normalize(RandomFloat3(center.xz + i));
					float3 grassCenter = center + dirTo0*noise.x + dirTo1*noise.y + dirTo2*noise.z;
					CreateGrass(grassCenter,n,stream);
				}
				
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 l = normalize(_WorldSpaceLightPos0.xyz);
				fixed shadow = SHADOW_ATTENUATION(i);
				half4 grassTex = tex2D(_GrassTex,i.uv);
				half ao = i.posObj.y * 1.5;
				grassTex.rgb *= ao;
				half4 col =lerp(_GroundColor,grassTex,i.color.g);
				half4 nol = dot(abs(i.normal),l) * .5 + .5;
				clip(col.a-_GrassCutoff);
				return col * nol;
				// return half4(i.normal,1);
				return dot(i.normal,l) * shadow;
			}

			ENDCG
		}

	}
 }
