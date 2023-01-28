Shader "Custom/TestGeom"
{
	Properties
	{
		_SpikeLength("Spike Length", Range(-1, 1)) = 0
	}

	SubShader
	{
		Pass
		{
			Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry" "LightMode" = "ForwardBase"}
//			Cull off
			CGPROGRAM

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
			    // float4 uv : TEXCOORD0;
			};
			struct v2g {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				// float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			struct g2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				SHADOW_COORDS(2)
				// float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			half _SpikeLength;

			v2g vert(appdata v) 
			{
				v2g o;
				o.pos = v.vertex;
				o.normal = v.normal;
				// o.uv=v.uv;
				return o;
			}

			g2f CreateG2F(v2g i)
			{
				g2f o;
				o.pos = i.pos;
				o.normal = UnityObjectToWorldNormal(i.normal);
				o.pos = UnityObjectToClipPos(o.pos);
				TRANSFER_SHADOW(o);
				return o;
			}

			[maxvertexcount(9)]
			void geo(triangle  v2g p[3], inout TriangleStream<g2f> stream)
			{
				float3 t0 = p[1].pos-p[0].pos;
				float3 t1 = p[2].pos-p[0].pos;
				float3 n = normalize(cross(t0,t1));
				// 椎体尖端点
				v2g spike;
				spike.pos =  float4(
									.33 * (p[0].pos.xyz + p[1].pos.xyz + p[2].pos.xyz) + _SpikeLength * n
									,1);

				//有三个面能被看见，依次计算它们
				//第一个面
				float3 n1 =  normalize(cross(spike.pos.xyz-p[1].pos.xyz,p[0].pos.xyz-p[1].pos.xyz));
				p[0].normal = n1;
				spike.normal = n1;
				p[2].normal = n1;
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(p[1]));
				stream.Append(CreateG2F(spike));
				
				stream.RestartStrip();
				
				//第二个面的
				float3 n2 =  normalize(cross(p[0].pos.xyz-p[2].pos.xyz,spike.pos.xyz-p[2].pos.xyz));
				p[1].normal = n2;
				spike.normal = n2;
				p[2].normal = n2;
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(spike));
				stream.Append(CreateG2F(p[2]));
				stream.RestartStrip();
				
				//第三个面的
				float3 n3 =  normalize(cross(p[2].pos.xyz-p[1].pos.xyz,spike.pos.xyz-p[1].pos.xyz));
				p[1].normal = n3;
				spike.normal = n3;
				p[2].normal = n3;
				stream.Append(CreateG2F(p[2]));
				stream.Append(CreateG2F(spike));
				stream.Append(CreateG2F(p[1]));
				stream.RestartStrip();			
			}

			fixed4 frag(g2f i) : SV_Target
			{
				float3 l = normalize(_WorldSpaceLightPos0.xyz);
				fixed shadow = SHADOW_ATTENUATION(i);
				// return half4(i.normal,1);
				return dot(i.normal,l) * shadow;
			}

			ENDCG
		}
		
		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM

			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag

			#include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

			struct appdata {
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			    // float4 uv : TEXCOORD0;
			};
			struct v2g {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				// float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			struct g2f {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				
				// float4 uv : TEXCOORD1;
				// float4 color : TEXCOORD0;
			};

			half _SpikeLength;

			v2g vert(appdata v) 
			{
				v2g o;
				o.pos = v.vertex;
				o.normal = v.normal;
				// o.uv=v.uv;
				return o;
			}

			g2f CreateG2F(v2g i)
			{
				g2f o;
				o.pos = i.pos;
				o.normal = i.normal;
				o.pos = UnityObjectToClipPos(o.pos);
				TRANSFER_SHADOW(o);
				return o;
			}

			[maxvertexcount(9)]
			void geo(triangle  v2g p[3], inout TriangleStream<g2f> stream)
			{
				float3 t0 = p[1].pos-p[0].pos;
				float3 t1 = p[2].pos-p[0].pos;
				float3 n = normalize(cross(t0,t1));
				// 椎体尖端点
				v2g spike;
				spike.pos =  float4(
									.33 * (p[0].pos.xyz + p[1].pos.xyz + p[2].pos.xyz) + _SpikeLength * n
									,1);

				//有三个面能被看见，依次计算它们
				//第一个面
				float3 n1 =  normalize(cross(spike.pos.xyz-p[1].pos.xyz,p[0].pos.xyz-p[1].pos.xyz));
				p[0].normal = n1;
				spike.normal = n1;
				p[2].normal = n1;
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(p[1]));
				stream.Append(CreateG2F(spike));
				
				stream.RestartStrip();
				
				//第二个面的
				float3 n2 =  normalize(cross(p[0].pos.xyz-p[2].pos.xyz,spike.pos.xyz-p[2].pos.xyz));
				p[1].normal = n2;
				spike.normal = n2;
				p[2].normal = n2;
				stream.Append(CreateG2F(p[0]));
				stream.Append(CreateG2F(spike));
				stream.Append(CreateG2F(p[2]));
				stream.RestartStrip();
				
				//第三个面的
				float3 n3 =  normalize(cross(p[2].pos.xyz-p[1].pos.xyz,spike.pos.xyz-p[1].pos.xyz));
				p[1].normal = n3;
				spike.normal = n3;
				p[2].normal = n3;
				stream.Append(CreateG2F(p[2]));
				stream.Append(CreateG2F(spike));
				stream.Append(CreateG2F(p[1]));
				stream.RestartStrip();			
			}

			fixed4 frag(g2f i) : SV_Target
			{
				return 1;
			}

			ENDCG
        }

	}
 }
