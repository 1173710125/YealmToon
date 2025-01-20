#ifndef TOON_SURFACE_INCLUDED
#define TOON_SURFACE_INCLUDED

struct ToonCommonSurfaceData
{
    half3 albedo;
    half3 normalWS;
    half3 normalTS;

    half metallic;
    half roughness;
};

struct ToonEyeSurfaceData
{
    half3 albedo;

    half3 matcapNormalWS;

    half3 highlightSpecular;
};

#endif