#ifndef TOON_SURFACE_INCLUDED
#define TOON_SURFACE_INCLUDED

struct ToonCommonSurfaceData
{
    half3 albedo;
    half3 normalWS;
    half3 normalTS;

    half metallic;
    half3 emission;
    half roughness;

};

#endif