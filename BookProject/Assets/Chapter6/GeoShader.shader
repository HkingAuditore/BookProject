Shader "Unlit/GeoShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
    	Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom


            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal  : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2g
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;

                float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 color : TEXCOORD2;
            	float4 posObj : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2g vert (appdata v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            	o.normal = v.normal;
                return o;
            }

			[maxvertexcount(6)] 
			void geom(triangle v2g p[3], inout TriangleStream<g2f> stream)
			{
            	float3 t0 = p[1].vertex - p[0].vertex;
            	float3 t1 = p[2].vertex - p[0].vertex;
            	float3 n = normalize(cross(t0,t1));
            	float4 center = .33*(p[0].vertex + p[1].vertex + p[2].vertex);
            	center.w = 1;
				for (int i = 0; i < 3; i++) 
				{
					g2f o;
					o.posObj = p[i].vertex;
					o.pos =UnityObjectToClipPos(o.posObj);
					o.normal = n;
					o.normal = UnityObjectToWorldNormal(o.normal);
					o.uv  = p[i].uv ;
					o.color  = float4(1,1,1,1);
					//将每个顶点添加到TriangleStream流里
					stream.Append(o);
				}
            	stream.RestartStrip();

				g2f o0;
            	o0.posObj = 1;
				o0.posObj.xyz = center + -0.1*normalize(t0);
				o0.pos =UnityObjectToClipPos(o0.posObj);
				o0.normal = normalize(t1);
				o0.normal = UnityObjectToWorldNormal(o0.normal);
				o0.uv  = float2(0,0);
				o0.color  = float4(0,1,0,1);
				//将每个顶点添加到TriangleStream流里
				stream.Append(o0);
            	
				g2f o1;
            	o1.posObj = 1;
				o1.posObj.xyz = center + 0.1*normalize(t0);
				o1.pos =UnityObjectToClipPos(o1.posObj);
				o1.normal = normalize(t1);
				o1.normal = UnityObjectToWorldNormal(o1.normal);
				o1.uv  = float2(1,0);
				o1.color  = float4(0,1,0,1);
				//将每个顶点添加到TriangleStream流里
				stream.Append(o1);
            	
				g2f o2;
            	o2.posObj = 1;
				o2.posObj.xyz = center + 0.5*n;
				o2.pos =UnityObjectToClipPos(o2.posObj);
				o2.normal = normalize(t1);
				o2.normal = UnityObjectToWorldNormal(o2.normal);
				o2.uv  = float2(0.5,1);
				o2.color  = float4(0,1,0,1);
				//将每个顶点添加到TriangleStream流里
				stream.Append(o2);

				


				//添加三角面
				//每输出点足够对应相应的图元后
				//都要RestartStrip()一下再继续构成下一图元
				stream.RestartStrip();
			}

            fixed4 frag (g2f i) : SV_Target
            {
                float3 n = normalize(i.normal);
                float3 l= normalize(_WorldSpaceLightPos0.xyz);
            	float3 v = UnityWorldSpaceViewDir(mul(unity_ObjectToWorld,i.posObj));
				float vdotn = saturate(dot(normalize(n),normalize(v)));
                fixed4 col = tex2D(_MainTex, i.uv);
            	// return i.color;
            	return half4(i.uv,0,1);
                return dot(n,l);
            }
            ENDCG
        }
    }
}
