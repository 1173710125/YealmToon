#ifndef TOON_COMMON_INPUT_INCLUDED
#define TOON_COMMON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half4 _ShadowTint;

    half4 _HighlightColorTint;
    half _HighlightDarken;

    half3 _FaceFrontDirection;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_HighlightMap);        SAMPLER(sampler_HighlightMap);
TEXTURE2D(_RampLightingMap);        SAMPLER(sampler_RampLightingMap);

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

inline void InitializeToonSurfaceData(float2 uv, float3 positionWS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonEyeSurfaceData outSurfaceData)
{
    #ifdef _PARALLAX
        half3 tangentView = viewParallax;
        float2 parallaxUV = uv - tangentView.xy * inputData.parallaxHeight;
        float2 originUV = uv;
        uv = lerp(originUV, parallaxUV, inputData.pupilMask);
    #endif

    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    // other
    outSurfaceData.faceFrontDirection = _FaceFrontDirection;
    outSurfaceData.highlightDarken = _HighlightDarken;
}

#endif
