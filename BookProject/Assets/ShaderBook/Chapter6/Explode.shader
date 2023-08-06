Shader "Chapter6/Explode"
{
	Properties
	{
		_Color("Color Tint", Color) = (1,1,1,1)
		_Emission1("Emission1", Color) = (1,1,1,1)
		_Emission2("Emission2", Color) = (1,1,1,1)
		_Height("Height", Range(-1.5, 0.5)) = 0
		_TotalHeight("Total Height", Float) = 1
		_Strength("Explosion Strenth", Range(0, 10)) = 2
		_Scale("Scale", Range(0, 5)) = 1
	}
    SubShader
    {
        Tags { "RenderType"="Opaque"}
		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			Cull Off
			 CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#include "UnityCG.cginc" 

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2g
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float EmissionParam : TEXCOORD1;
			};

			fixed4 _Color;
			fixed4 _Emission1;
			fixed4 _Emission2;
			float _Height;
			float _TotalHeight;
			float _Strength;
			float _Scale;

			float3 randto3D(float3 seed)
			{
				float3 f = sin(float3(dot(seed, float3(127.1, 337.1, 256.2)), dot(seed, float3(129.8, 782.3, 535.3))
				, dot(seed, float3(269.5, 183.3, 337.1))));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float rand(float3 seed)
			{
				float f = sin(dot(seed, float3(127.1, 337.1, 256.2)));
				f = -1 + 2 * frac(f * 43785.5453123);
				return f;
			}

			float3x3 AngleAxis3x3(float angle, float3 axis)
			{
				float s, c;
				sincos(angle, s, c);
				float x = axis.x;
				float y = axis.y;
				float z = axis.z;
				return float3x3(
					x * x + (y * y + z * z) * c, x * y * (1 - c) - z * s, x * z * (1 - c) - y * s,
					x * y * (1 - c) + z * s, y * y + (x * x + z * z) * c, y * z * (1 - c) - x * s,
					x * z * (1 - c) - y * s, y * z * (1 - c) + x * s, z * z + (x * x + y * y) * c
				);
			}

			float3x3 rotation3x3(float3 angle)
			{
				return mul(AngleAxis3x3(angle.x, float3(0, 0, 1)), mul(AngleAxis3x3(angle.y, float3(1, 0, 0)), AngleAxis3x3(angle.z, float3(0, 1, 0))));
			}

			v2g vert(a2v v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.normal = v.normal;
				return o;
			}

			g2f VertexOutput(float3 pos, float3 normal, float param)
			{
				g2f o;
				o.pos = UnityObjectToClipPos(float4(pos, 1));
				o.normal = UnityObjectToWorldNormal(normal);
				o.EmissionParam = param;
				return o;
			}

			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream)
			{
				float3 p0 = IN[0].vertex.xyz;
				float3 p1 = IN[1].vertex.xyz;
				float3 p2 = IN[2].vertex.xyz;

				float3 n0 = IN[0].normal;
				float3 n1 = IN[1].normal;
				float3 n2 = IN[2].normal;

				float3 center = (p0 + p1 + p2) / 3;
				float offset = (center.y - _Height) * _TotalHeight;

				if (offset < 0)
				{
					triStream.Append(VertexOutput(p0, n0, -1));
					triStream.Append(VertexOutput(p1, n1, -1));
					triStream.Append(VertexOutput(p2, n2, -1));
					triStream.RestartStrip();
					return;
				}

				else if (offset > 1)
					return;

				float ss_offset = smoothstep(0, 1, offset);

				float3 translation = (n0 + n1 + n2) / 3 * ss_offset * _Strength;
				float3x3 rotationMatrix = rotation3x3(rand(center.zyx));
				float scale = _Scale - ss_offset;

				float3 t_p0 = mul(rotationMatrix, p0 - center) * scale + center + translation;
				float3 t_p1 = mul(rotationMatrix, p1 - center) * scale + center + translation;
				float3 t_p2 = mul(rotationMatrix, p2 - center) * scale + center + translation;
				float3 normal = normalize(cross(t_p1 - t_p0, t_p2 - t_p0));

				triStream.Append(VertexOutput(t_p0, normal, ss_offset));
				triStream.Append(VertexOutput(t_p1, normal, ss_offset));
				triStream.Append(VertexOutput(t_p2, normal, ss_offset));
				triStream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
				fixed4 color = step(0, i.EmissionParam) * _Emission1 + step(i.EmissionParam, 0) * _Color;
				if(i.EmissionParam > 0)
				color = lerp(color, _Emission2, i.EmissionParam);
				return color;
			}
			ENDCG
		}      
    }
    FallBack "Diffuse"
}

