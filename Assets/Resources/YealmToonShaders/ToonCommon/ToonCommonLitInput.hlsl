#ifndef TOON_COMMON_INPUT_INCLUDED
#define TOON_COMMON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half _NormalScale;

    half4 _SpecularColor;
    half _SpecularSize;
    half _SpecularSmooth;

    float _OutlineWidth;
    half4 _OutlineColor;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_NormalMap);        SAMPLER(sampler_NormalMap);
TEXTURE2D(_SpecularMap);        SAMPLER(sampler_SpecularMap);
TEXTURE2D(_RampLightingMap);        SAMPLER(sampler_RampLightingMap);
TEXTURE2D(_RampSSSMap);        SAMPLER(sampler_RampSSSMap);

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

half3 SampleNormalTS(float2 uv)
{
    return UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalScale);;
}

half3 SampleSpecular(float2 uv)
{
    return SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv).rgb;
}


inline void InitializeToonSurfaceData(float2 uv, float3 positionWS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonCommonSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    // normal
    outSurfaceData.normalTS = SampleNormalTS(uv);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);


    outSurfaceData.normalWS = TransformTangentToWorld(outSurfaceData.normalTS, tangentToWorld);
    outSurfaceData.normalWS = NormalizeNormalPerPixel(outSurfaceData.normalWS);

    outSurfaceData.specularColor = SampleSpecular(uv) * _SpecularColor.rgb;
    outSurfaceData.specularSize = _SpecularSize;
    outSurfaceData.specularSmooth = _SpecularSmooth;
}

#endif
