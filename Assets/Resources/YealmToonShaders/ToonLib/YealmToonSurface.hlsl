#ifndef TOON_SURFACE_INCLUDED
#define TOON_SURFACE_INCLUDED

struct ToonCommonSurfaceData
{
    half3 albedo;

// pbr
    half metallic;
    half roughness;

// not pbr
    half3 specularColor;
    half specularSize;
    half specularSmooth;
};

struct ToonEyeSurfaceData
{
    half3 albedo;

    half3 faceFrontDirection;

    half highlightDarken;
};

struct ToonFaceSurfaceData
{
    half3 albedo;

    // not pbr
    half3 specularColor;
    half specularSize;
    half specularSmooth;

    // sdfShadow
    half faceShadowPow;
    half faceShadowSmoothness;
    half faceShadowValue1;
    half faceShadowValue2;

    half3 faceFrontDirection;
    half3 faceRightDirection;
};
#endif