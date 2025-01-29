#ifndef TOON_HAIR_DEPTH_PASS_INCLUDED
#define TOON_HAIR_DEPTH_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

struct Attributes
{
    float4 positionOS     : POSITION;
    float4 tangentOS    : TANGENT;
    float3 normalOS      : NORMAL;
    float2 texcoord     : TEXCOORD0;
    float3 smoothNormal : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    #if defined(_ALPHA_CLIP)
        float2 uv       : TEXCOORD0;
    #endif
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings DepthOnlyVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    input.positionOS.xyz = GetFOVAdjustedPositionOS(input.positionOS.xyz, _ObjectCenterPositionWS);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    #if defined(_ALPHA_CLIP)
        output.uv = input.texcoord;
    #endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

half DepthOnlyFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #if defined(_ALPHA_CLIP)
        half alpha = SampleAlbedoAlpha(input.uv).a;
        clip(alpha - 0.5);
    #endif

    // #if defined(LOD_FADE_CROSSFADE)
    //     LODFadeCrossFade(input.positionCS);
    // #endif

    return input.positionCS.z;
}
#endif