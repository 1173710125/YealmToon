#ifndef TOON_COMMON_INPUT_INCLUDED
#define TOON_COMMON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    half4 _BaseColor;
    half _NormalScale;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

half3 SampleNormalTS(float2 uv)
{
    return UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalScale);
}

inline void InitializeToonSurfaceData(float2 uv, float3 positionWS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonCommonSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(uv);
    outSurfaceData.albedo = albedoAlpha.rgb;

    // normal
    outSurfaceData.normalTS = SampleNormalTS(uv);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);


    outSurfaceData.normalWS = TransformTangentToWorld(outSurfaceData.normalTS, tangentToWorld);
    outSurfaceData.normalWS = NormalizeNormalPerPixel(outSurfaceData.normalWS);
}

#endif
