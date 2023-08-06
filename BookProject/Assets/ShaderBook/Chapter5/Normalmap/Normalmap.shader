Shader "Chapter5/Normalmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Main Color", Color) = (1, 1, 1, 1)
    	
        [Header(Normal Map)]
    	_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapIntensity ("Normal Map Intensity", Float) = 1
    	[Toggle(_INVERT_NORMAL_Y)]_INVERT_NORMAL_Y("Invert Normal Y Axis",Float) = 0
    	
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ _INVERT_NORMAL_Y
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
            	
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            float4 _MainTex_ST;
            half4 _MainColor;

            half _NormalMapIntensity;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
            	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.objectPos = v.vertex;
                return o;
            }

            half3 GetNormalMap(float3 normal, float4 tangent, float2 uv, float intensity,bool invertY)
            {
            	// 计算副切线
	            float3 bitangent = cross(normal, tangent) * tangent.w;
            	float3 normalMap = UnpackScaleNormal(tex2D(_NormalMap, uv.xy), intensity);
            	float3 newNormal = normalize(
											normalMap.x * tangent +
											normalMap.y * (invertY?-1:1) * bitangent +
											normalMap.z * normal
									);
            	return newNormal;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #if _INVERT_NORMAL_Y
                float3 normal = GetNormalMap(i.normal,i.tangent,i.uv,_NormalMapIntensity,true);
                #else
                float3 normal = GetNormalMap(i.normal, i.tangent, i.uv, _NormalMapIntensity, false);
                #endif
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                
                // 漫反射
                half4 albedo = tex2D(_MainTex,i.uv) * _MainColor;
                half diffuse = saturate(dot(normal,lightDir));
            	half3 diffuseFinal = diffuse * albedo * _LightColor0.rgb;
            	
                return half4(diffuseFinal, 1);                
            }
            ENDCG
        }
    }
}
