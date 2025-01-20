#ifndef TOON_COMMON_INPUT_INCLUDED
#define TOON_COMMON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half4 _ShadowTint;

    half4 _HighlightColorTint;
    half _HighlightDarken;
    half _MatcapReflectionStrength;
    half _MatcapNormalScale;

    half3 _FaceFrontDirection;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_HighlightMap);        SAMPLER(sampler_HighlightMap);
TEXTURE2D(_MatcapNormalMap);        SAMPLER(sampler_MatcapNormalMap);
TEXTURE2D(_MatcapReflectionMap);        SAMPLER(sampler_MatcapReflectionMap);

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

half3 SampleNormalTS(float2 uv)
{
    return UnpackNormalScale(SAMPLE_TEXTURE2D(_MatcapNormalMap, sampler_MatcapNormalMap, uv), _MatcapNormalScale);
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

    // matcap
    half3 normalTS = SampleNormalTS(uv);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);

    outSurfaceData.matcapNormalWS = TransformTangentToWorld(normalTS, tangentToWorld);
    outSurfaceData.matcapNormalWS = NormalizeNormalPerPixel(outSurfaceData.matcapNormalWS);

    outSurfaceData.faceFrontDirection = _FaceFrontDirection;
    outSurfaceData.highlightDarken = _HighlightDarken;
}

#endif
