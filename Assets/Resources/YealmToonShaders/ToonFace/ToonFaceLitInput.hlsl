#ifndef TOON_FACE_INPUT_INCLUDED
#define TOON_FACE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "../ToonLib/YealmToonSurface.hlsl"
#include "../ToonLib/YealmToonInput.hlsl"

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

    half4 _RimLightColor;
    half _RimLightStrength;
    half _RimLightAlign;
    half _RimLightSmoothness;
CBUFFER_END

TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampLightingMap);        SAMPLER(sampler_RampLightingMap);
TEXTURE2D(_RampSSSMap);        SAMPLER(sampler_RampSSSMap);
TEXTURE2D(_FaceSDFMap);        SAMPLER(sampler_FaceSDFMap); // 脸部sdf 用于控制阴影范围

half4 SampleAlbedoAlpha(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
}

inline void InitializeToonInputData(float2 uv, float3 positionWS, float4 positionCS, half3 tangentWS, half3 bitangentWS, half3 normalWS, inout ToonInputData outInputData)
{
    outInputData.screenUV = GetNormalizedScreenSpaceUV(positionCS);

    outInputData.meshUV = uv;
    outInputData.positionWS = positionWS;
    outInputData.positionVS = TransformWorldToView(positionWS);
    
    outInputData.normalWS = NormalizeNormalPerPixel(normalWS);

    // 脸部法线特殊处理
    half3 faceUpDirection = cross(_FaceFrontDirection, _FaceRightDirection);
    half3 projectOnUpVector = dot(outInputData.normalWS, faceUpDirection) * faceUpDirection;
    half3 projectOnPlane = normalize(outInputData.normalWS - projectOnUpVector);
    outInputData.normalWS = projectOnPlane;
    outInputData.normalVS = TransformWorldToViewDir(outInputData.normalWS);

    outInputData.rimLightColor = _RimLightColor;
    outInputData.rimLightStrength = _RimLightStrength;
    outInputData.rimLightAlign = _RimLightAlign;
    outInputData.rimLightSmoothness = _RimLightSmoothness;
}

inline void InitializeToonSurfaceData(ToonInputData inputData, inout ToonFaceSurfaceData outSurfaceData)
{
    // albedo
    half4 albedoAlpha = SampleAlbedoAlpha(inputData.meshUV);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    half3 cheekColor = _CheekColor.rgb;
    half cheekAlpha = _CheekColor.a * albedoAlpha.a;
    outSurfaceData.albedo = lerp(outSurfaceData.albedo, cheekColor, cheekAlpha);

    // faceSDFMap
    outSurfaceData.faceShadowValue1 = SAMPLE_TEXTURE2D_LOD(_FaceSDFMap, sampler_FaceSDFMap, float2(inputData.meshUV.x, inputData.meshUV.y), 0).r;
    outSurfaceData.faceShadowValue2 = SAMPLE_TEXTURE2D_LOD(_FaceSDFMap, sampler_FaceSDFMap, float2(-inputData.meshUV.x, inputData.meshUV.y), 0).r;
    outSurfaceData.faceShadowPow = _FaceShadowPow;
    outSurfaceData.faceShadowSmoothness = _FaceShadowSmoothness;


    outSurfaceData.faceFrontDirection = _FaceFrontDirection;
    outSurfaceData.faceRightDirection = _FaceRightDirection;
}

#endif