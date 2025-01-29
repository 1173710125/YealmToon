#ifndef TOON_LIGHTING_INCLUDED
#define TOON_LIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "YealmToonSurface.hlsl"
#include "YealmToonInput.hlsl"
#include "YealmToonCommon.hlsl"

half _EnvLightingIntensity;

half4 _UpPartSkyColor;
half4 _DownPartSkyColor;
half4 _UndergroundPartSkyColor;

TEXTURECUBE(_EnvCubeMap); SAMPLER(sampler_EnvCubeMap);

//////////////////////////////////////////////////////////////////////////////////////
// face光照 only
//////////////////////////////////////////////////////////////////////////////////////

half FaceShadowMapAttenuation(ToonFaceSurfaceData surfaceData, Light light)
{
    float3 lightDir = light.direction.xyz;
    half3 front = surfaceData.faceFrontDirection;
    half3 right = surfaceData.faceRightDirection;

    half faceShadowValue1 = surfaceData.faceShadowValue1;
    half faceShadowValue2 = surfaceData.faceShadowValue2;


    bool switchShadow = (dot(normalize(right.xz), normalize(lightDir.xz))) > 0;
    half flippedFaceShadow = switchShadow ? faceShadowValue2 : faceShadowValue1;

    float lightAngleHorizontal = acos(dot(normalize(front.xz),  normalize(lightDir.xz))); // 存疑，歪头情况下是不是就出错了
    float threshold = lightAngleHorizontal / 3.141592653;
    threshold = pow(threshold, max(1 / surfaceData.faceShadowPow, 0));

    float lightAttenuation = saturate(smoothstep(threshold - surfaceData.faceShadowSmoothness,
                                                 threshold + surfaceData.faceShadowSmoothness, flippedFaceShadow));

    return 1.0 - lightAttenuation;
}

half3 ShadeSingleLightFace(ToonInputData inputData, ToonFaceSurfaceData surfaceData, Light light, bool isAdditionalLight)
{
    half3 N = inputData.normalWS;
    half3 L = light.direction;

    half NoL01 = dot(N,L) * 0.5 + 0.5;

    // light's distance & angle fade for point light & spot light (see GetAdditionalPerObjectLight(...) in Lighting.hlsl)
    half distanceAttenuation = 1;
    if(isAdditionalLight == true)
        distanceAttenuation = min(4,light.distanceAttenuation); //clamp to prevent light over bright if point/spot light too close to vertex


    // N dot L
    // half litOrShadowArea = NoL01;

    // occlusion
    // litOrShadowArea *= surfaceData.occlusion;

    // light's shadow map
    // litOrShadowArea *= lerp(1,light.shadowAttenuation,_ReceiveShadowMappingAmount);
    half litOrShadowArea = FaceShadowMapAttenuation(surfaceData, light);

    // 根据litOrShadowArea的值 采样lightingRamp贴图，获取对应颜色
    half3 litOrShadowColor = SAMPLE_TEXTURE2D(_RampLightingMap, sampler_RampLightingMap, float2(litOrShadowArea, 0)).rgb;

    // half3 litOrShadowColor = lerp(_ShadowTint.rgb, 1, litOrShadowArea);

    half3 lightAttenuationRGB = litOrShadowColor * distanceAttenuation;

    // saturate() light.color to prevent over bright
    // additional light reduce intensity since it is additive
    return saturate(light.color) * lightAttenuationRGB * (isAdditionalLight ? 0.25 : 1);
}

//////////////////////////////////////////////////////////////////////////////////////
// 通用光照函数
//////////////////////////////////////////////////////////////////////////////////////

// depth rimlight
float3 ShadeDepthRimLight(ToonInputData inputData, Light mainLight, float3 baseColor)
{
    float3 offsetPosVS = float3(inputData.positionVS.xy + inputData.normalVS.xy * inputData.rimLightStrength * 0.1,
                                inputData.positionVS.z);
    float4 offsetPosCS = TransformWViewToHClip(offsetPosVS);
    float4 offsetPosVP = TransformHClipToViewPortPos(offsetPosCS);
    float offsetDepth = SampleSceneDepth(offsetPosVP.xy);
    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
    float depth = SampleSceneDepth(inputData.screenUV);
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
    float rimMask = smoothstep(0, 0.9, depthDiff);
    float3 depthRimLighting = rimMask * inputData.rimLightColor.rgb;
    depthRimLighting *= mainLight.shadowAttenuation;

    return lerp(baseColor, depthRimLighting, rimMask);
}

real3 ShadeFresnelRimLight(ToonInputData inputData, Light mainLight, half3 viewDirWS)
{
    half NdotL = saturate(dot(mainLight.direction, inputData.normalWS));
    real rimPower = 1.0 - inputData.rimLightStrength;
    real NdotV = dot(viewDirWS, inputData.normalWS);
    real rim = saturate(
        (1.0 - NdotV) * lerp(1, NdotL, saturate(inputData.rimLightAlign)) * lerp(
            1, 1 - NdotL, saturate(-inputData.rimLightAlign)));
    float delta = fwidth(rim);
    real3 rimLighting = smoothstep(rimPower - delta, rimPower + delta + inputData.rimLightSmoothness, rim) * inputData.rimLightColor.rgb;
    return rimLighting * mainLight.shadowAttenuation;
}

// local shadow by depth
half HandleDepthOffsetShadow()
{

}

// 非PBR 通用高光
// 眼睛高光不要用这个
float3 LightingSpecularToon(float3 lightDir, float3 normal, float3 viewDir, half3 specular, half size, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = saturate(dot(normal, halfVec));
    float spec = saturate(pow(NdotH, 4));
    spec = smoothstep((1.0 - size) , (1.0 - size)  + smoothness, spec);
    float3 specularReflection = lerp(0, specular, spec) * spec;
    return specularReflection;
}

// 头发 kajiya-kay高光

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
half3 ShadeSingleLight(half3 normalWS, Light light, bool isAdditionalLight)
{
    half3 N = normalWS;
    half3 L = light.direction;

    half NoL01 = dot(N,L) * 0.5 + 0.5;

    // light's distance & angle fade for point light & spot light (see GetAdditionalPerObjectLight(...) in Lighting.hlsl)
    // Lighting.hlsl -> https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
    half distanceAttenuation = 1;
    if(isAdditionalLight == true)
        distanceAttenuation = min(4,light.distanceAttenuation); //clamp to prevent light over bright if point/spot light too close to vertex


    // N dot L
    // simplest 1 line cel shade, you can always replace this line by your own method!
    float litOrShadowArea = NoL01;

    // occlusion
    // litOrShadowArea *= surfaceData.occlusion;

    // face ignore celshade since it is usually very ugly using NoL method
    // litOrShadowArea = _IsFace? lerp(0.5,1,litOrShadowArea) : litOrShadowArea;

    // light's shadow map
    // litOrShadowArea *= lerp(1,light.shadowAttenuation,_ReceiveShadowMappingAmount);
    litOrShadowArea *= light.shadowAttenuation;

    // 根据litOrShadowArea的值 采样lightingRamp贴图，获取对应颜色
    half3 litOrShadowColor = SAMPLE_TEXTURE2D(_RampLightingMap, sampler_RampLightingMap, float2(litOrShadowArea, 0)).rgb;

    // half3 litOrShadowColor = lerp(_ShadowTint.rgb, 1, litOrShadowArea);

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
half3 calToonCommonLighting(ToonInputData inputData, ToonCommonSurfaceData surfaceData)
{
    float4 shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    mainLight.shadowAttenuation = lerp(mainLight.shadowAttenuation, 1, GetShadowFade(inputData.positionWS)); // shadow fade

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------直接光照------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
    // 主平行光
    half3 mainLightAtten = ShadeSingleLight(inputData.normalWS, mainLight, false);
    half3 mainLightResult = mainLightAtten * (surfaceData.albedo + LightingSpecularToon(mainLight.direction, inputData.normalWS, viewDirWS, surfaceData.specularColor, surfaceData.specularSize, surfaceData.specularSmooth));

    // 额外光
    half3 additionalLightsResult = half3(0, 0, 0);
    #if defined(_ADDITIONAL_LIGHTS)
        #if USE_FORWARD_PLUS

        uint lightIndex;
        ClusterIterator _urp_internal_clusterIterator = ClusterInit(inputData.screenUV, inputData.positionWS, 0);
        [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { 
            lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; 
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light addLight = GetAdditionalLight(lightIndex, inputData.positionWS);
            half3 addLightAtten = ShadeSingleLight(inputData.normalWS, addLight, true);
            additionalLightsResult += addLightAtten * (surfaceData.albedo + LightingSpecularToon(addLight.direction, inputData.normalWS, viewDirWS, surfaceData.specularColor, surfaceData.specularSize, surfaceData.specularSmooth));
        }
        #endif
    #endif

// ------------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------环境光照------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------------------------------------------
    // 天空环境光diffuse
    half3 envLightResult = ShadeEnvLight(surfaceData) * surfaceData.albedo;

    // 环境光spe by probe

    // composite
    half3 finalColor = mainLightResult + additionalLightsResult + envLightResult;

    // 边缘光
    finalColor += ShadeFresnelRimLight(inputData, mainLight, viewDirWS);


//     // 全局光照 SSR and so on

    // return envLightResult;
    return finalColor;
}

half3 calToonEyeLighting(ToonInputData inputData, ToonEyeSurfaceData surfaceData)
{
    float4 shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
    
    half3 finalColor = half3(0, 0, 0);

    // mainLight
    half3 mainLightResult = ShadeSingleLight(surfaceData.faceFrontDirection, mainLight, false);
    finalColor += mainLightResult * surfaceData.albedo;

    // 额外光
    half3 additionalLightsResult = half3(0, 0, 0);
    #if defined(_ADDITIONAL_LIGHTS)
        #if USE_FORWARD_PLUS

        uint lightIndex;
        ClusterIterator _urp_internal_clusterIterator = ClusterInit(inputData.screenUV, inputData.positionWS, 0);
        [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { 
            lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; 
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light addLight = GetAdditionalLight(lightIndex, inputData.positionWS);
            additionalLightsResult += ShadeSingleLight(surfaceData.faceFrontDirection, addLight, true) * surfaceData.albedo;
        }
        #endif
    #endif
    finalColor += additionalLightsResult;

    half3 viewParallax = abs(normalize(TransformWorldToViewDir(viewDirWS)));
    // 高光
    // #ifdef _EYE_HIGHLIGHT
    //     half3 lightParallax = normalize(TransformWorldToViewDir(mainLight.direction));
    //     half3 eyeH = normalize(viewParallax + lightParallax);
    //     half eyeNdotHFlat = dot(eyeH, -surfaceData.faceFrontDirection);
        
    //     float2 eyeHighlightUV = HighlightUV;
    //     // 考虑下后面需不需要这种高光旋转的操作，需要贴图以及UV满足一定条件
    //     // float maxRotation = inputData.eyeHighlightRotateDegree;
    //     // eyeHighlightUV = RotateUVDeg(eyeHighlightUV, float2(0.5,0.5),min(eyeNdotHFlat.x * maxRotation, maxRotation));
    //     half3 eyeHighlightCol = SAMPLE_TEXTURE2D_X(_HighlightMap, sampler_HighlightMap, eyeHighlightUV).rgb * _HighlightColorTint;
    //     eyeHighlightCol *= _HighlightColorTint;

    //     half eyeNoL = saturate(dot(surfaceData.faceFrontDirection, mainLight.direction));

    //     eyeHighlightCol = lerp(eyeHighlightCol, eyeNoL * eyeHighlightCol, surfaceData.highlightDarken);
    //     finalColor += eyeHighlightCol;

    // #endif

    // envDiffuse
    half3 envDiffuse = CalculateSkyboxIrradiance(surfaceData.faceFrontDirection);
    finalColor += envDiffuse * surfaceData.albedo;

    // EnvSpecular
    // 不想用matcap方式，可否使用probe的方式解决？
    // finalColor += MatCapHightlight(inputData, mainLight) * lerp(1, inputData.pupilMask, inputData.usePupilMask);

    // 边缘光
    finalColor += ShadeFresnelRimLight(inputData, mainLight, viewDirWS);

    return finalColor;
}

half3 calToonFaceLighting(ToonInputData inputData, ToonFaceSurfaceData surfaceData)
{
    float4 shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    Light mainLight = GetMainLight(shadowCoord);
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
    
    half3 finalColor = half3(0, 0, 0);

    // mainLight
    half3 mainLightResult = ShadeSingleLightFace(inputData, surfaceData, mainLight, false);
    finalColor += mainLightResult * surfaceData.albedo;

    // 额外光
    half3 additionalLightsResult = half3(0, 0, 0);
    #if defined(_ADDITIONAL_LIGHTS)
        #if USE_FORWARD_PLUS

        uint lightIndex;
        ClusterIterator _urp_internal_clusterIterator = ClusterInit(inputData.screenUV, inputData.positionWS, 0);
        [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { 
            lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; 
            FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

            Light addLight = GetAdditionalLight(lightIndex, inputData.positionWS);
            additionalLightsResult += ShadeSingleLight(inputData.normalWS, addLight, true) * surfaceData.albedo;
        }
        #endif
    #endif
    finalColor += additionalLightsResult;

    // envDiffuse
    half3 envDiffuse = CalculateSkyboxIrradiance(surfaceData.faceFrontDirection);
    finalColor += envDiffuse * surfaceData.albedo;

    // EnvSpecular
    // 不想用matcap方式，可否使用probe的方式解决？
    // finalColor += MatCapHightlight(inputData, mainLight) * lerp(1, inputData.pupilMask, inputData.usePupilMask);

    // 边缘光
    finalColor += ShadeFresnelRimLight(inputData, mainLight, viewDirWS);

    return finalColor;
}

#endif