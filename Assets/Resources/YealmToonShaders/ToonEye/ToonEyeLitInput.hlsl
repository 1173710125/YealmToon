#ifndef TOON_COMMON_INPUT_INCLUDED
#define TOON_COMMON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"
#include "../ToonLib/YealmToonInput.hlsl"

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

inline void InitializeToonInputData(float2 uv, float3 positionWS, float4 positionCS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonInputData outInputData)
{
    outInputData.screenUV = GetNormalizedScreenSpaceUV(positionCS);

    outInputData.meshUV = uv;
    #ifdef _PARALLAX
        half3 tangentView = viewParallax;
        float2 parallaxUV = inputData.meshUV - tangentView.xy * inputData.parallaxHeight;
        float2 originUV = inputData.meshUV;
        inputData.meshUV = lerp(originUV, parallaxUV, inputData.pupilMask);
    #endif

    outInputData.positionWS = positionWS;
    outInputData.positionVS = TransformWorldToView(positionWS);

}

inline void InitializeToonSurfaceData(ToonInputData inputData, inout ToonEyeSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(inputData.meshUV);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    // other
    outSurfaceData.faceFrontDirection = _FaceFrontDirection;
    outSurfaceData.highlightDarken = _HighlightDarken;
}

#endif
