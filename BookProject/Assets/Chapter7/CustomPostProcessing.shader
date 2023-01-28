Shader "CustomPP/CustomPostProcessing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _EdgeThreshold("Edge Threshold" ,Range(0,1)) = 1
        _EdgeSize("Edge Size" ,Range(0,5)) = 1
        _EdgeColor("Edge Color" ,Color) = (1,1,1,1)
    }
    SubShader
    {
        Cull Off
		ZTest Always
		ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            sampler2D _MainTex;
            // _MainTex的像素宽度，四个分量为（1/宽、1/高、宽、高）
            float4 _MainTex_TexelSize;
            half _EdgeThreshold;
            half _EdgeSize;
            half4 _EdgeColor;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.pos);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 取样
                half3 pixels[9] = { tex2D(_MainTex,i.uv+half2(-1,-1)*_MainTex_TexelSize.xy * _EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(0,-1)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(1,-1)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(-1,0)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv).rgb,
                                    tex2D(_MainTex,i.uv+half2(1,0)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(-1,1)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(0,1)*_MainTex_TexelSize.xy*_EdgeSize).rgb,
                                    tex2D(_MainTex,i.uv+half2(1,1)*_MainTex_TexelSize.xy*_EdgeSize).rgb};

                half sobelX[9] = {-1,-2,-1,
                                    0,0,0,
                                    1,2,1};
                half sobelY[9] = {-1,0,1,
                                    -2,0,2,
                                    -1,0,1};

                half gradientX = 0;
                half gradientY = 0;
                for (int i = 0; i < 9; i++)
                {
                    gradientX += pixels[i] * sobelX[i];
                    gradientY += pixels[i] * sobelY[i];
                }
                // 我们不关心梯度的方向，所以取梯度的绝对值
                half edge = step(_EdgeThreshold,saturate(abs(gradientX)+abs(gradientY)));

                return lerp(half4(pixels[4],1),_EdgeColor,edge);
            }
            ENDCG
        }
    }
}
