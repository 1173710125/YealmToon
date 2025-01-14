#ifndef TOON_COMMON_FORWARD_PASS_INCLUDED
#define TOON_COMMON_FORWARD_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "../ToonLib/YealmToonLighting.hlsl"

//////////////////////////////////////////////////////////////////////////////////////
// struct
//////////////////////////////////////////////////////////////////////////////////////
struct Attributes
{
    float4 positionOS    : POSITION;
    float4 tangentOS    : TANGENT;
    float3 normalOS      : NORMAL;
    half4 information   : COLOR;
    float2 texcoord      : TEXCOORD0;
};

struct Varyings
{
    float2 uv                       : TEXCOORD0; //xy:texture uv
    float3 positionWS                  : TEXCOORD1;    // xyz: posWS
    half3 normalWS                 : TEXCOORD2;     // xyz: normal
    half3 tangentWS                : TEXCOORD3;     // xyz: tangent 
    half3 bitangentWS              : TEXCOORD4;


    float4 positionCS                  : SV_POSITION;
};

Varyings LitPassVertexCommon(Attributes input)
{
    Varyings output = (Varyings)0;

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;

    return output;
}


void LitPassFragmentCommon(
    Varyings input
    , out half4 outColor : SV_Target0
)
{
    float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
    // float depth = LinearEyeDepth(input.positionCS.z, _ZBufferParams);

    ToonCommonSurfaceData toonCommonSurfaceData = (ToonCommonSurfaceData)0;
    InitializeToonSurfaceData(input.uv, input.positionWS, input.tangentWS, input.bitangentWS, input.normalWS, toonCommonSurfaceData);


    // BRDF光照结果
    half3 toonLighting = calToonCommonLighting(toonCommonSurfaceData, input.positionWS, screenUV);
    outColor = half4(toonLighting, 1);
}

#endif