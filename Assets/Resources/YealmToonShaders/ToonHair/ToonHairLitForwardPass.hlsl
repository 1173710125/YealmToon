#ifndef TOON_HAIR_FORWARD_PASS_INCLUDED
#define TOON_HAIR_FORWARD_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "../ToonLib/YealmToonLighting.hlsl"
#include "../ToonLib/YealmToonOutline.hlsl"

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

Varyings LitPassVertexCommon(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    output.positionWS = vertexInput.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

#ifdef ToonShaderIsOutline
    //从自定义空间 将平滑法线还原到OS空间
    float3 tangent = input.tangentOS;
    float3 bitangent = normalize(cross(input.tangentOS, input.normalOS));
    float3 normal = input.normalOS;
    float3 smoothNormal = input.smoothNormal;


    float3 smoothNormalOS = float3(tangent.x * smoothNormal.x + bitangent.x * smoothNormal.y + normal.x * smoothNormal.z,
                                        tangent.y * smoothNormal.x + bitangent.y * smoothNormal.y + normal.y * smoothNormal.z,
                                        tangent.z * smoothNormal.x + bitangent.z * smoothNormal.y + normal.z * smoothNormal.z);
    smoothNormalOS = normalize(smoothNormalOS);
    float3 smoothNormalWS = TransformObjectToWorldNormal(smoothNormalOS);
    output.positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, smoothNormalWS, _OutlineWidth);
#endif

    output.uv.xy = input.texcoord;
    output.positionCS = TransformWorldToHClip(output.positionWS);

#ifdef ToonShaderIsOutline
    // // [Read ZOffset mask texture]
    // // we can't use tex2D() in vertex shader because ddx & ddy is unknown before rasterization, 
    // // so use tex2Dlod() with an explict mip level 0, put explict mip level 0 inside the 4th component of param uv)
    // float outlineZOffsetMaskTexExplictMipLevel = 0;
    // float outlineZOffsetMask = tex2Dlod(_OutlineZOffsetMaskTex, float4(input.uv,0,outlineZOffsetMaskTexExplictMipLevel)).r; //we assume it is a Black/White texture

    // // [Remap ZOffset texture value]
    // // flip texture read value so default black area = apply ZOffset, because usually outline mask texture are using this format(black = hide outline)
    // outlineZOffsetMask = 1-outlineZOffsetMask;
    // outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart,_OutlineZOffsetMaskRemapEnd,outlineZOffsetMask);// allow user to flip value or remap

    // // [Apply ZOffset, Use remapped value as ZOffset mask]
    output.positionCS = NiloGetNewClipPosWithZOffset(output.positionCS, 0.01);// + 0.03 * _IsFace
#endif

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

    // 描边颜色
    #ifdef ToonShaderIsOutline
        toonLighting *= _OutlineColor; // 考虑是否 *toonLighting
    #endif

    // 雾效


    outColor = half4(toonLighting, 1);
}

#endif