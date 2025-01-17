#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "YealmToonSurface.hlsl"

half _SpecularThreshold;
half2 _BrightShadowStepRange;
half _EnvLightingIntensity;

half4 _UpPartSkyColor;
half4 _DownPartSkyColor;
half4 _UndergroundPartSkyColor;

TEXTURECUBE(_EnvCubeMap); SAMPLER(sampler_EnvCubeMap);

//////////////////////////////////////////////////////////////////////////////////////
// 通用光照函数
//////////////////////////////////////////////////////////////////////////////////////

half3 ShadeRimLight(ToonCommonSurfaceData surfaceData, half3 viewDirWS, bool blendAlbedo = false)
{
    half NoV = dot(surfaceData.normalWS, viewDirWS);
    half rimStrength = 1.0 - smoothstep(_RimLightThreshold, _RimLightThreshold + _RimLightFadeSpeed, NoV);
    half3 rimColor = lerp(0, _RimLightColor, rimStrength);

    return rimColor;
}

// env diffuse
half3 CalculateSkyboxIrradiance(half3 normalWS)
{
    //室外lerp三个位置的颜色
    half up = dot(normalWS, half3(0.0, 1.0, 0.0));
    half down = -up;
    up = max(0, up);
    down = max(0, down);
    half mid = 1.0 - up - down;
    half3 env = _UpPartSkyColor.rgb * up + _DownPartSkyColor.rgb * mid + _UndergroundPartSkyColor.rgb * down;
    return env * _EnvLightingIntensity;
}

// Most important part: lighting equation, edit it according to your needs, write whatever you want here, be creative!
// This function will be used by all direct lights (directional/point/spot)
half3 ShadeSingleLight(ToonCommonSurfaceData surfaceData, Light light, bool isAdditionalLight = false)
{
    half3 N = surfaceData.normalWS;
    half3 L = light.direction;

    half NoL = dot(N,L);

    // light's distance & angle fade for point light & spot light (see GetAdditionalPerObjectLight(...) in Lighting.hlsl)
    // Lighting.hlsl -> https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
    half distanceAttenuation = 1;
    if(isAdditionalLight == true)
        distanceAttenuation = min(4,light.distanceAttenuation); //clamp to prevent light over bright if point/spot light too close to vertex


    // N dot L
    // simplest 1 line cel shade, you can always replace this line by your own method!
    half litOrShadowArea = smoothstep(_BrightShadowStepRange.x, _BrightShadowStepRange.y, NoL);;

    // occlusion
    // litOrShadowArea *= surfaceData.occlusion;

    // face ignore celshade since it is usually very ugly using NoL method
    // litOrShadowArea = _IsFace? lerp(0.5,1,litOrShadowArea) : litOrShadowArea;

    // light's shadow map
    // litOrShadowArea *= lerp(1,light.shadowAttenuation,_ReceiveShadowMappingAmount);

    half3 litOrShadowColor = lerp(_ShadowTint.rgb, 1, litOrShadowArea);

    half3 lightAttenuationRGB = litOrShadowColor * distanceAttenuation;

    // saturate() light.color to prevent over bright
    // additional light reduce intensity since it is additive
    return saturate(light.color) * lightAttenuationRGB * (isAdditionalLight ? 0.25 : 1);
}

// 环境光计算
half3 ShadeEnvLight(ToonCommonSurfaceData surfaceData, bool isFace = false)
{
    // diffuse
    half3 diffuseLight = CalculateSkyboxIrradiance(surfaceData.normalWS);

    // specular


    //half3 envDiffuse = bakedGI;
    // half3 envSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, half(1.0)); probe使用方式？
    // 不做toon操作，直接加上去，可以柔和光照效果
    return saturate(diffuseLight);
}

//////////////////////////////////////////////////////////////////////////////////////
// todo：pbr-BRDF光照计算
//////////////////////////////////////////////////////////////////////////////////////
half3 calToonCommonLighting(ToonCommonSurfaceData surfaceData, float3 positionWS, float2 normalizedScreenSpaceUV)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    mainLight.shadowAttenuation = lerp(mainLight.shadowAttenuation, 1, GetShadowFade(positionWS)); // shadow fade

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------直接光照------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
    // 主平行光
    half3 mainLightResult = ShadeSingleLight(surfaceData, mainLight, false);

    // half3 stepSpecular = step(_SpecularThreshold, NoH) * diffuse;

    // 额外光
    // lightingData.additionalLightsResult = half3(0, 0, 0);
    // #if defined(_ADDITIONAL_LIGHTS)
    //     #if USE_FORWARD_PLUS

    //     uint lightIndex;
    //     ClusterIterator _urp_internal_clusterIterator = ClusterInit(normalizedScreenSpaceUV, positionWS, 0);
    //     [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { 
    //         lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; 
    //         FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

    //         Light addLight = GetAdditionalLight(lightIndex, positionWS);
    //         half addLightNoL = max(dot(surfaceData.normalWS, addLight.direction), 0.0);
    //             if (IsMatchingLightLayer(addLight.layerMask, meshRenderingLayers))
    //             {
    //                 half3 addLightColor = addLight.color * (addLightNoL * addLight.distanceAttenuation);
    //                 lightingData.additionalLightsResult += addLightColor * CalDirectBRDF(brdfData, surfaceData.normalWS, addLight.direction, viewDirWS);
    //             }
    //     }
    //     #endif
    // #endif

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------环境光照------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
    // 天空环境光diffuse
    half3 envLightResult = ShadeEnvLight(surfaceData);

    // 环境光spe by probe

    // 边缘光
    // half3 rimLightResult = ShadeRimLight(surfaceData, viewDirWS);


//     // 全局光照 SSR and so on

    // return envLightResult;
    return (mainLightResult + envLightResult) * surfaceData.albedo;
}

#endif