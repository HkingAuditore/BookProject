Shader "Chapter4/StencilWindow"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1)
        _StencilRef("StencilRef",Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("StencilComp",int) = 3 
        [Enum(UnityEngine.Rendering.StencilOp)]_StencilPassOp("StencilPassOp",int) = 2 
    }
    SubShader
    {
        Tags { "Queue"="Geometry+1" }
        ZWrite Off
        Stencil
        {
            Ref [_StencilRef]
            Comp [_StencilComp]
            Pass [_StencilPassOp]
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            half4 _Color;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}
