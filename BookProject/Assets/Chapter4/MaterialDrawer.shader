Shader "Unlit/MaterialDrawer"
{
    Properties
    {
        //主纹理
        [MainTexture]_Tex("Texture", 2D) = "white" {}

        //在面板中隐藏
        [HideInInspector] _MainTex2("Hide Texture", 2D) = "white" {}

        //去除Tiling和Offset
        [NoScaleOffset] _MainTex3("No Scale/Offset Texture", 2D) = "white" {}

        [PerRendererData] _MainTex4("PerRenderer Texture", 2D) = "white" {}

        // 法线纹理
        [Normal] _MainTex5("Normal Texture", 2D) = "white" {}

        //主颜色
        [MainColor]_Col("Color", Color) = (1,0,0,1)

        //HDR颜色
        [HDR] _HDRColor("HDR Color", Color) = (1,0,0,1)

        _Vector("Vector", Vector) = (0,0,0,0)
        
        // 去除Gamma矫正
        [Gamma] _GVector("Gamma Vector", Vector) = (0,0,0,0)

        [Header(A group of things)]

        // 创建"_Tog_ON" shader关键字
        [Toggle] _Tog("Auto keyword toggle", Float) = 0

        // 创建 "ENABLE_TOGG" shader关键字
        [Toggle(ENABLE_TOGG)] _Togg("Keyword toggle", Float) = 0

        // 枚举混合模式
        [Enum(UnityEngine.Rendering.BlendMode)] _Blend("Blend mode Enum", Float) = 1

        // One-1、SrcAlpha-5的下拉菜单
        [Enum(One,1,SrcAlpha,5)] _Blend2("Blend mode subset", Float) = 1

        // 创建 _OVERLAY_NONE, _OVERLAY_ADD, _OVERLAY_MULTIPLY shader 关键字.
        [KeywordEnum(None, Add, Multiply)] _Overlay("Keyword Enum", Float) = 0

        // 三次方映射的滑动条
        [PowerSlider(3.0)] _Shininess("Power Slider", Range(0.01, 1)) = 0.08

        // 整数的滑动条
        [IntRange] _IntSlider("Int Range", Range(0, 255)) = 100

        // 小空隙
        [Space] _Prop1("Small amount of space", Float) = 0

        // 大空隙
        [Space(50)] _Prop2("Large amount of space", Float) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
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
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
