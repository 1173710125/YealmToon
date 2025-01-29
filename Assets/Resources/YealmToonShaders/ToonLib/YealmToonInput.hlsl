#ifndef TOON_INPUT_INCLUDED
#define TOON_INPUT_INCLUDED

struct ToonInputData
{
    // position
    float3 positionWS;
    float3 positionVS;
    float4 positionCS;

    // normal
    half3 normalTS;
    half3 normalWS;
    half3 normalVS;

    // uv
    float2 meshUV;
    float2 screenUV;

    //depth rim lighting
    half4 rimLightColor;
    half rimLightStrength;
    half rimLightAlign;
    half rimLightSmoothness;

    // depth offset shadow
    half offsetShadowDistance;

};

#endif