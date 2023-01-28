Shader "Unlit/BlendingTrace"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthPow("Depth Min" ,float) = 0
        _DepthMax("Depth Max" ,float) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100
        BlendOp Max
        Blend One One
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _DepthMin;
            half _DepthMax;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag(v2f i) : COLOR
            {
                // 拍摄结果中uv的x与平面的相反，因此对uv.x取了1-x
                float depth = tex2D(_MainTex,half2(1-i.uv.x,i.uv.y));
                float trace = 1 - smoothstep(_DepthMin,_DepthMax,depth);
                return saturate(trace);
            }
            ENDCG
        }
    }
}