#ifndef TOON_HAIR_INPUT_INCLUDED
#define TOON_HAIR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"
#include "../ToonLib/YealmToonInput.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half4 _ShadowTint;
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

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);;
}

half3 SampleNormalTS(float2 uv)
{
    return UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv), _NormalScale);;
}

half3 SampleSpecular(float2 uv)
{
    return SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, uv).rgb;
}

inline void InitializeToonInputData(float2 uv, float3 positionWS, float4 positionCS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonInputData outInputData)
{
    outInputData.screenUV = GetNormalizedScreenSpaceUV(positionCS);

    outInputData.meshUV = uv;
    outInputData.positionWS = positionWS;
    outInputData.positionVS = TransformWorldToView(positionWS);
    
    outInputData.normalTS = SampleNormalTS(uv);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);
    outInputData.normalWS = TransformTangentToWorld(outInputData.normalTS, tangentToWorld);
    outInputData.normalWS = NormalizeNormalPerPixel(outInputData.normalWS);
    outInputData.normalVS = TransformWorldToViewDir(outInputData.normalWS);

}

inline void InitializeToonSurfaceData(ToonInputData inputData, inout ToonCommonSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(inputData.meshUV);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    // high light
    outSurfaceData.specularColor = SampleSpecular(inputData.meshUV) * _SpecularColor.rgb;
    outSurfaceData.specularSize = _SpecularSize;
    outSurfaceData.specularSmooth = _SpecularSmooth;
}

#endif
