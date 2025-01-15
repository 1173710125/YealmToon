using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("YealmToon/GlobalSettings")]
public class YealmToonSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter specularThreshold = new ClampedFloatParameter(0.8f, 0f, 1f);
    public ClampedFloatParameter brightShadowThreshold = new ClampedFloatParameter(0.5f, 0f, 1f);


    public bool IsActive()
    {
        return true;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
