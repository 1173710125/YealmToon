#ifndef TOON_COMMON_FORWARD_PASS_INCLUDED
#define TOON_COMMON_FORWARD_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "../ToonLib/YealmToonLighting.hlsl"
#include "../ToonLib/YealmToonOutline.hlsl"

//////////////////////////////////////////////////////////////////////////////////////
// struct
//////////////////////////////////////////////////////////////////////////////////////
struct Attributes
{
    float4 positionOS    : POSITION;
    float4 tangentOS    : TANGENT;
    float3 normalOS      : NORMAL;
    float2 texcoord      : TEXCOORD0;
    float3 smoothNormal : TEXCOORD3;
};

struct Varyings
{
    float2 uv                       : TEXCOORD0; //xy:texture uv
    float3 positionWS                  : TEXCOORD1;    // xyz: posWS
    half3 normalWS                 : TEXCOORD2;     // xyz: normal
    half3 tangentWS                : TEXCOORD3;     // xyz: tangent 
    half3 bitangentWS              : TEXCOORD4;


    float4 positionCS                  : SV_POSITION;
};

Varyings LitPassVertexFace(Attributes input)
{
    Varyings output = (Varyings)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    output.positionWS = vertexInput.positionWS;
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    #ifdef ToonShaderIsOutline
        //从自定义空间 将平滑法线还原到OS空间
        float3 tangent = input.tangentOS;
        float3 bitangent = normalize(cross(input.tangentOS, input.normalOS));
        float3 normal = input.normalOS;
        float3 smoothNormal = input.smoothNormal;


        float3 smoothNormalOS = float3(tangent.x * smoothNormal.x + bitangent.x * smoothNormal.y + normal.x * smoothNormal.z,
                                            tangent.y * smoothNormal.x + bitangent.y * smoothNormal.y + normal.y * smoothNormal.z,
                                            tangent.z * smoothNormal.x + bitangent.z * smoothNormal.y + normal.z * smoothNormal.z);
        smoothNormalOS = normalize(smoothNormalOS);
        float3 smoothNormalWS = TransformObjectToWorldNormal(smoothNormalOS);
        output.positionWS = TransformPositionWSToOutlinePositionWS(vertexInput.positionWS, vertexInput.positionVS.z, smoothNormalWS, _OutlineWidth);
    #endif

    output.uv.xy = input.texcoord;
    output.positionCS = TransformWorldToHClip(output.positionWS);

    #ifdef ToonShaderIsOutline
        output.positionCS = NiloGetNewClipPosWithZOffset(output.positionCS, 0.01);// + 0.03 * _IsFace
    #endif

    output.normalWS = normalInput.normalWS;
    output.tangentWS = normalInput.tangentWS;
    output.bitangentWS = normalInput.bitangentWS;

    return output;
}


void LitPassFragmentFace(
    Varyings input
    , out half4 outColor : SV_Target0
)
{
    ToonInputData toonInputData = (ToonInputData)0;
    InitializeToonInputData(input.uv, input.positionWS, input.positionCS, input.tangentWS, input.bitangentWS, input.normalWS, toonInputData);

    ToonFaceSurfaceData toonFaceSurfaceData = (ToonFaceSurfaceData)0;
    InitializeToonSurfaceData(toonInputData, toonFaceSurfaceData);


    // BRDF光照结果
    half3 toonLighting = calToonFaceLighting(toonInputData, toonFaceSurfaceData);

    // 描边颜色
    #ifdef ToonShaderIsOutline
        toonLighting *= _OutlineColor; // 考虑是否 *toonLighting
    #endif

    // 雾效
    
    outColor = half4(toonLighting, 1);
}

#endif