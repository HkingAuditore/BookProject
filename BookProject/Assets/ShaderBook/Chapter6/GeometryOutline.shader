Shader "Unlit/GeometryOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

		Pass
		{
			Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry" "LightMode" = "ForwardBase"}
			CGPROGRAM

			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata {
			    float4 vertex : POSITION;
			    float3 normal : NORMAL;
			};
			struct v2g {
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
			};

			struct g2f {
				float4 pos : SV_POSITION;
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
			   o.pos = UnityObjectToClipPos(o.pos);
			   return o;
			}
			
			[maxvertexcount(6)]
			void geom(triangle v2g p[3], inout LineStream<g2f> stream)
			{
			   // 三角面的第一条边
			   stream.Append(CreateG2F(p[0]));
			   stream.Append(CreateG2F(p[1]));
			   // 三角面的第二条边
			   stream.Append(CreateG2F(p[0]));
			   stream.Append(CreateG2F(p[2]));
			   // 三角面的第三条边
			   stream.Append(CreateG2F(p[1]));
			   stream.Append(CreateG2F(p[2]));
			}


			fixed4 frag(g2f i) : SV_Target
			{
				return 1;
			}

			ENDCG
		}
    }
}
