#ifndef TOON_INPUT_INCLUDED
#define TOON_INPUT_INCLUDED

struct ToonInputData
{
    float3 positionWS;
    float3 positionVS;

    half3 normalTS;
    half3 normalWS;
    half3 normalVS;

    float2 meshUV;
    float2 screenUV;
};

#endif