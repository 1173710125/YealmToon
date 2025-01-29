#ifndef TOON_EYE_FORWARD_PASS_INCLUDED
#define TOON_EYE_FORWARD_PASS_INCLUDED

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
    float2 texcoord      : TEXCOORD0;
    float3 smoothNormal : TEXCOORD3;
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

Varyings LitPassVertexEye(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.uv.xy = input.texcoord;

    // perspective correction
    vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
    ToonCharacterPerspectiveCorrection(vertexInput.positionVS, UNITY_MATRIX_MV[2][3]);
    output.positionWS = TransformViewToWorld(vertexInput.positionVS);
    output.positionCS = TransformWViewToHClip(vertexInput.positionVS);

    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;

    return output;
}


void LitPassFragmentEye(
    Varyings input
    , out half4 outColor : SV_Target0
)
{
    ToonInputData toonInputData = (ToonInputData)0;
    InitializeToonInputData(input.uv, input.positionWS, input.positionCS, input.tangentWS, input.bitangentWS, input.normalWS, toonInputData);

    ToonEyeSurfaceData toonEyeSurfaceData = (ToonEyeSurfaceData)0;
    InitializeToonSurfaceData(toonInputData, toonEyeSurfaceData);


    // BRDF光照结果
    half3 toonLighting = calToonEyeLighting(toonInputData, toonEyeSurfaceData);


    // 雾效


    outColor = half4(toonLighting, 1);
}

#endif