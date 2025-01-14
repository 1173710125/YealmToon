#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "YealmToonSurface.hlsl"

half _ShadowThreshold;

//////////////////////////////////////////////////////////////////////////////////////
// todo：pbr-BRDF光照计算
//////////////////////////////////////////////////////////////////////////////////////
half3 calToonCommonLighting(ToonCommonSurfaceData surfaceData, float3 positionWS, float2 normalizedScreenSpaceUV)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    mainLight.shadowAttenuation = lerp(mainLight.shadowAttenuation, 1, GetShadowFade(positionWS)); // shadow fade
    half NoL = dot(surfaceData.normalWS, mainLight.direction);
    half NoL01 = NoL * 0.5 + 0.5;
    half a = step(_ShadowThreshold, NoL01);
    return a.xxx;
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);


// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------直接光照------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
    // 主平行光

    half3 mainLightColor = (mainLight.distanceAttenuation * mainLight.shadowAttenuation * NoL01) * mainLight.color; // (mainLight.distanceAttenuation * mainLight.shadowAttenuation * NoL) * mainLight.color
    half3 mainLightResult = mainLightColor;

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

// // ------------------------------------------------------------------------------------------------------------------------------------
// // ------------------------------------------------------------环境光照------------------------------------------------------------------
// // ------------------------------------------------------------------------------------------------------------------------------------
//     // 天空环境光
//     // half3 skyboxLighting = CalculateSkyboxIrradiance(surfaceData.normalWS);
//     // lightingData.skyboxLightResult =  skyboxLighting * brdfData.brdfDiffuse; 

//     // reflection probe
//     // half NoV = saturate(dot(surfaceData.normalWS, viewDirWS));
//     // half3 reflectVector = reflect(-viewDirWS, surfaceData.normalWS);
//     // half3 probeSpecularLighting = CalculateProbeIrradiance(reflectVector, positionWS, brdfData.roughness, normalizedScreenSpaceUV, skyboxLighting);
//     // half3 EnvironmentBRDF = calEnvBRDF(brdfData, NoV); 
//     // lightingData.probesLightResult = probeSpecularLighting * EnvironmentBRDF * brdfData.metallic; // * metallic 魔道做法用金属度相乘 使得非金属 不会受到probe影响


//     // 全局光照 SSR and so on


    return half4(mainLightResult, 1);
}

#endif