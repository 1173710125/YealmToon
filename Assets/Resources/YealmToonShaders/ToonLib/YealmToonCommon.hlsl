#ifndef TOON_COMMON_INCLUDED
#define TOON_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

TEXTURE2D(_ToonDepthTexture); SAMPLER(sampler_ToonDepthTexture);

float _PerspectiveCorrectionIntensity;
float3 GetFOVAdjustedPositionOS(float3 positionOS, float3 objectCenterWS)
{
    // Adjusts object-space position based on field-of-view and a shift factor. 
    // use to perspective distortion. 
    float3 objectCenterVS = TransformWorldToView(objectCenterWS);
    float3 fovAdjustedPositionVS = mul(UNITY_MATRIX_MV, float4(positionOS.xyz, 1)).xyz;
    fovAdjustedPositionVS.z = (fovAdjustedPositionVS.z - objectCenterVS.z)/(_PerspectiveCorrectionIntensity + 1) + objectCenterVS.z;
    return mul(Inverse(UNITY_MATRIX_MV), float4(fovAdjustedPositionVS, 1)).xyz;
}

float4 TransformHClipToViewPortPos(float4 positionCS)
{
    float4 o = positionCS * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
    o.zw = positionCS.zw;
    return o / o.w;
}

float SampleCharacterDepthOffsetShadow(float2 uv)
{
    return SAMPLE_TEXTURE2D_X(_ToonDepthTexture, sampler_ToonDepthTexture, UnityStereoTransformScreenSpaceTex(uv)).r;
}
#endif