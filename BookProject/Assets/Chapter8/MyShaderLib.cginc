#if !defined(MY_SHADER_LIB)
#define MY_SHADER_LIB

#include "UnityCG.cginc"

struct appdata_myshaderlib
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
};

struct v2f_myshaderlib
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 worldPos : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 objectPos : TEXCOORD3;
    float4 tangent: TEXCOORD4;
    float4 screenPos: TEXCOORD5;
};

v2f_myshaderlib vert_myshaderlib (appdata_myshaderlib v)
{
    v2f_myshaderlib o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.objectPos = v.vertex;
    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    o.screenPos = ComputeScreenPos(o.pos);
    return o;
}

#endif