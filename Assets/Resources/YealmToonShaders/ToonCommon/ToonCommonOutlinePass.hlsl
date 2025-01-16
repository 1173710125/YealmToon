#ifndef TOON_COMMON_OUTLINE_PASS_INCLUDED
#define TOON_COMMON_OUTLINE_PASS_INCLUDED

//////////////////////////////////////////////////////////////////////////////////////
// struct
//////////////////////////////////////////////////////////////////////////////////////
struct Attributes
{
    float4 positionOS    : POSITION;
    float4 tangentOS    : TANGENT;
    float3 normalOS      : NORMAL;
    float2 texcoord      : TEXCOORD0;
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

Varyings ToonOutlineVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    output.positionCS = TransformObjectToHClip(input.positionOS);

    float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, input.normalOS);
    float2 extendDir = normalize(mul((float2x2)UNITY_MATRIX_P, norm.xy));

    float4 nearUpperRight = mul(unity_CameraInvProjection, float4(1, 1, UNITY_NEAR_CLIP_VALUE, _ProjectionParams.y));//将近裁剪面右上角位置的顶点变换到观察空间
    float aspect = abs(nearUpperRight.y / nearUpperRight.x);//求得屏幕宽高比
    extendDir.x *= aspect;

    output.positionCS.xy += extendDir * (output.positionCS.w * _OutlineWidth);
#if UNITY_REVERSED_Z
    output.positionCS.z -= 0.001;
    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#else
    output.positionCS.z += 0.001;
    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE);
#endif

    return output;
}


void ToonOutlineFragment(
    Varyings input
    , out half4 outColor : SV_Target0
)
{
    outColor = half4(_OutlineColor.rgb, 1);
}

#endif
