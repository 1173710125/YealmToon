#ifndef TOON_COMMON_INCLUDED
#define TOON_COMMON_INCLUDED

TEXTURE2D(_ToonDepthTexture); SAMPLER(sampler_ToonDepthTexture);

float _PerspectiveCorrectionIntensity; // 1 为不变，0~1  1~1000
void ToonCharacterPerspectiveCorrection(inout float3 positionVS, float pivotZ)
{
    positionVS.z = (positionVS.z - pivotZ) / (_PerspectiveCorrectionIntensity + 0.001) + pivotZ;
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