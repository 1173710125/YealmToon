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

// matcap
real3 MatCapHightlight()
{
    // #ifdef _MATCAP_HIGHLIGHT_MAP
    // float3 matcapUp = mul((float3x3)UNITY_MATRIX_I_V, float3(0, 1, 0));
    // float3 matcapRollFixedUp = float3(0, 1, 0);
    // float rollStabilizeFactor = 1.0 - saturate(dot(matcapUp, matcapRollFixedUp));
    // matcapUp = lerp(matcapUp, matcapRollFixedUp, rollStabilizeFactor * inputData.matCapRollStabilize);

    // float3 right = normalize(cross(matcapUp, -inputData.viewDirectionWS));
    // matcapUp = cross(-inputData.viewDirectionWS, right);
    // float2 matcapUV = mul(float3x3(right, matcapUp, inputData.viewDirectionWS), inputData.matCapNormalWS).xy;
    // matcapUV = matcapUV * 0.5 + 0.5;
    // float4 matcapRGBA = SAMPLE_TEXTURE2D(_MatCapReflectionMap, sampler_MatCapReflectionMap, matcapUV);
    // //TODO add option to handle shadowed matcap highlight
    // matcapRGBA *= inputData.matCapReflectionStrength;
    // return matcapRGBA.rgb * matcapRGBA.a;
    // #else
    return real3(0,0,0);
    // #endif
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

// _BrightShadowStepRange和 _ShadowTint 在有ramp后可以被完全替换
// Most important part: lighting equation, edit it according to your needs, write whatever you want here, be creative!
// This function will be used by all direct lights (directional/point/spot)
half3 ShadeSingleLight(half3 normalWS, Light light, bool isAdditionalLight = false)
{
    half3 N = normalWS;
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
    litOrShadowArea *= light.shadowAttenuation;

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
    half3 diffuseLight = _DownPartSkyColor.rgb * _EnvLightingIntensity;

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
    half3 mainLightResult = ShadeSingleLight(surfaceData.normalWS, mainLight, false);

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
    //         half3 addLightColor = addLight.color * (addLightNoL * addLight.distanceAttenuation);
    //         lightingData.additionalLightsResult += addLightColor * CalDirectBRDF(brdfData, surfaceData.normalWS, addLight.direction, viewDirWS);
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
    return max(mainLightResult, envLightResult) * surfaceData.albedo;
}

half3 calToonEyeLighting(ToonEyeSurfaceData surfaceData, float3 positionWS, float2 normalizedScreenSpaceUV, float2 HighlightUV)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
    
    half3 finalColor = half3(0, 0, 0);

    // mainLight
    half3 mainLightResult = ShadeSingleLight(surfaceData.faceFrontDirection, mainLight, false);
    finalColor += mainLightResult * surfaceData.albedo;

    // #if defined(_ADDITIONAL_LIGHTS)
    // uint pixelLightCount = GetAdditionalLightsCount();

    // #if USE_FORWARD_PLUS
    // for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    // {
    //     FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
    //     //handle extra directional light
    //     Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
    //     #ifdef _LIGHT_LAYERS
    //     if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    //     #endif
    //     {
    //         finalColor += ToonAdditionalLighting(light, inputData, brdfData);
    //     }
    // }
    // #endif

    // LIGHT_LOOP_BEGIN(pixelLightCount)
    //     //additional light
    //     Light light = GetAdditionalLight(lightIndex, inputData.positionWS, inputData.shadowMask);
    //     #ifdef _LIGHT_LAYERS
    //     if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    //     #endif
    //     {
    //         finalColor += ToonAdditionalLighting(light, inputData, brdfData);
    //     }
    // LIGHT_LOOP_END
    // #endif

    half3 viewParallax = abs(normalize(TransformWorldToViewDir(viewDirWS)));
    // 高光
    #ifdef _EYE_HIGHLIGHT
        half3 lightParallax = normalize(TransformWorldToViewDir(mainLight.direction));
        half3 eyeH = normalize(viewParallax + lightParallax);
        half eyeNdotHFlat = dot(eyeH, -surfaceData.faceFrontDirection);
        
        float2 eyeHighlightUV = HighlightUV;
        // 考虑下后面需不需要这种高光旋转的操作，需要贴图以及UV满足一定条件
        // float maxRotation = inputData.eyeHighlightRotateDegree;
        // eyeHighlightUV = RotateUVDeg(eyeHighlightUV, float2(0.5,0.5),min(eyeNdotHFlat.x * maxRotation, maxRotation));
        half3 eyeHighlightCol = SAMPLE_TEXTURE2D_X(_HighlightMap, sampler_HighlightMap, eyeHighlightUV).rgb * _HighlightColorTint;
        eyeHighlightCol *= _HighlightColorTint;

        half eyeNoL = saturate(dot(surfaceData.faceFrontDirection, mainLight.direction));

        eyeHighlightCol = lerp(eyeHighlightCol, eyeNoL * eyeHighlightCol, surfaceData.highlightDarken);
        finalColor += eyeHighlightCol;

    #endif

    // EnvSpecular
    // 不想用matcap方式，可否使用probe的方式解决？
    // finalColor += MatCapHightlight(inputData, mainLight) * lerp(1, inputData.pupilMask, inputData.usePupilMask);

    return finalColor;;
}

#endif