Shader "Chapter6/Outline_Scaler"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineWidth("Outline Width",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            Stencil
            {
                Ref 2
                //Comp always
                Pass Replace
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                return col;
            }
            ENDCG
        }
        Pass
        {
            Stencil
            {
                Ref 1
                Comp greater
                Pass Replace
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _OutlineWidth;

            v2f vert(appdata v)
            {
                v2f o;
                // 观察空间法线
                float3 normal = normalize(mul(UNITY_MATRIX_MV, v.normal));
                // 观察空间坐标
                o.vertex = mul(unity_MatrixMV, v.vertex);
                float fov = 1 / (unity_CameraProjection[1].y);
                float depth = lerp(1,abs(o.vertex.z),-unity_CameraProjection[3].z);
                float4 a=mul(UNITY_MATRIX_P, o.vertex);
                
                // 只在观察空间中可见的 x 与 y 方向做外扩
                o.vertex.xy += normal.xy * _OutlineWidth*fov*depth*0.01;
                //最后变换至裁剪空间
                o.vertex = mul(UNITY_MATRIX_P, o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                return 0;
            }
            ENDCG
        }

    }
}