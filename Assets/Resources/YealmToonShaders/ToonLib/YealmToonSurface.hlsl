#ifndef TOON_SURFACE_INCLUDED
#define TOON_SURFACE_INCLUDED

struct ToonCommonSurfaceData
{
    half3 albedo;
    half3 normalWS;
    half3 normalTS;

    half metallic;
    half roughness;

    half3 faceFrontDirection;
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

    half3 normalWS;

    // sdfShadow
    half faceShadowPow;
    half faceShadowSmoothness;
    half faceShadowValue1;
    half faceShadowValue2;

    half3 faceFrontDirection;
    half3 faceRightDirection;
};
#endif