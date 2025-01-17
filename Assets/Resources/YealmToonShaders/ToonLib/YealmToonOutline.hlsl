#ifndef TOON_OUTLINE_INCLUDED
#define TOON_OUTLINE_INCLUDED

// If your project has a faster way to get camera fov in shader, you can replace this slow function to your method.
// For example, you write cmd.SetGlobalFloat("_CurrentCameraFOV",cameraFOV) using a new RendererFeature in C#.
// For this tutorial shader, we will keep things simple and use this slower but convenient method to get camera fov
float GetCameraFOV()
{
    //https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
    float t = unity_CameraProjection._m11;
    float Rad2Deg = 180 / 3.1415;
    float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
    return fov;
}

float ApplyOutlineDistanceFadeOut(float inputMulFix)
{
    //make outline "fadeout" if character is too small in camera's view
    return saturate(inputMulFix);
}

float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
{
    float cameraMulFix;

    ////////////////////////////////
    // Perspective camera case
    ////////////////////////////////

    // keep outline similar width on screen accoss all camera distance       
    cameraMulFix = abs(positionVS_Z);

    // can replace to a tonemap function if a smooth stop is needed
    cameraMulFix = ApplyOutlineDistanceFadeOut(cameraMulFix);

    // keep outline similar width on screen accoss all camera fov
    cameraMulFix *= GetCameraFOV();       


    return cameraMulFix * 0.00005; // mul a const to make return result = default normal expand amount WS
}

float3 TransformPositionWSToOutlinePositionWS(float3 positionWS, float positionVS_Z, float3 normalWS, float outlineWidth)
{
    //you can replace it to your own method! Here we will write a simple world space method for tutorial reason, it is not the best method!
    float outlineExpandAmount = outlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(positionVS_Z);
    
    return positionWS + normalWS * outlineExpandAmount; 
}

// Useful for:
// -Hide ugly outline on face/eye
// -Make eyebrow render on top of hair
// -Solve ZFighting issue without moving geometry
float4 NiloGetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
{
    ////////////////////////////////
    //Perspective camera case
    ////////////////////////////////
    float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
    float modifiedPositionVS_Z = -originalPositionCS.w + -viewSpaceZOffsetAmount; // push imaginary vertex
    float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
    originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
    return originalPositionCS;    

}

#endif