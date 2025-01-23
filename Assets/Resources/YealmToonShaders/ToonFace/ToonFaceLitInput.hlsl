#ifndef TOON_FACE_INPUT_INCLUDED
#define TOON_FACE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half4 _ShadowTint;

    half4 _OutlineColor;
    half _OutlineWidth;

    // face
    half _FaceShadowPow;
    half _FaceShadowSmoothness;
    half4 _CheekColor;

    half3 _FaceFrontDirection;
    half3 _FaceRightDirection;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampLightingMap);        SAMPLER(sampler_RampLightingMap);
TEXTURE2D(_RampSSSMap);        SAMPLER(sampler_RampSSSMap);
TEXTURE2D(_FaceSDFMap);        SAMPLER(sampler_FaceSDFMap); // 脸部sdf 用于控制阴影范围

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

inline void InitializeToonSurfaceData(float2 uv, float3 positionWS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonFaceSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    half3 cheekColor = _CheekColor.rgb;
    half cheekAlpha = _CheekColor.a * albedoAlpha.a;
    outSurfaceData.albedo = lerp(outSurfaceData.albedo, cheekColor, cheekAlpha);

    normalWS = normalize(normalWS);
    half3 faceUpDirection = cross(_FaceFrontDirection, _FaceRightDirection);
    half3 projectOnUpVector = dot(normalWS, faceUpDirection) * faceUpDirection;
    half3 projectOnPlane = normalize(normalWS - projectOnUpVector);
    outSurfaceData.normalWS = projectOnPlane;


    // faceSDFMap
    outSurfaceData.faceShadowValue1 = SAMPLE_TEXTURE2D_LOD(_FaceSDFMap, sampler_FaceSDFMap, float2(uv.x, uv.y), 0).r;
    outSurfaceData.faceShadowValue2 = SAMPLE_TEXTURE2D_LOD(_FaceSDFMap, sampler_FaceSDFMap, float2(-uv.x, uv.y), 0).r;
    outSurfaceData.faceShadowPow = _FaceShadowPow;
    outSurfaceData.faceShadowSmoothness = _FaceShadowSmoothness;


    outSurfaceData.faceFrontDirection = _FaceFrontDirection;
    outSurfaceData.faceRightDirection = _FaceRightDirection;
}

#endif